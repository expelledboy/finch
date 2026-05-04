import Foundation
import JavaScriptCore
import AppKit

// MARK: - Public types

struct BrowserSpec {
    let bundleId: String
    let args: [String]
}

struct Resolution {
    let browser: BrowserSpec
    let url: URL
}

// MARK: - Compiled internal forms
//
// At config load time we walk the JS export tree and translate every match
// pattern + rewrite into a native Swift representation. The hot path then
// uses these directly — JS is only re-entered for user-written `(url, ctx)`
// functions, which are the explicit slow path.

private enum Matcher {
    case regex(NSRegularExpression)     // bare string (hostname pattern) or /literal/
    case domain([String])                // domain("a.com", ...) marker
    case from([String])                  // from("com.foo", ...) marker
    case running([String])               // running("com.foo", ...) marker
    case fn(JSValue)                     // user (url, ctx) => bool function
}

private enum Rewriter {
    case strip(Set<String>, prefixes: [String])  // strip("utm_*", "fbclid")
    case literal(String)                          // url: "https://..."
    case fn(JSValue)                              // url: (url, ctx) => string
}

private enum Target {
    case browser(BrowserSpec)
    case fn(JSValue)
    case suppress    // open: null
}

private struct Rule {
    let matchers: [Matcher]    // OR semantics — any match triggers
    let target: Target
}

private struct RewriteRule {
    let matchers: [Matcher]
    let rewriter: Rewriter
}

// MARK: - Lazy resolve context

// Built lazily during a single resolve(). Expensive things (running app set,
// JS ctx object) are only constructed if a rule actually needs them.
private final class ResolveCtx {
    let url: String
    let opener: String
    let modifiers: NSEvent.ModifierFlags
    private var _running: Set<String>?
    private var _jsCtx: JSValue?
    private weak var jsContext: JSContext?

    init(url: String, opener: String, modifiers: NSEvent.ModifierFlags, jsContext: JSContext) {
        self.url = url; self.opener = opener; self.modifiers = modifiers
        self.jsContext = jsContext
    }

    func runningApps() -> Set<String> {
        if let r = _running { return r }
        let r = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
        _running = r
        return r
    }

    // Build the JS-visible context object. ~5.7µs per call — only built if
    // a user function predicate is actually invoked.
    func jsCtx() -> JSValue {
        if let c = _jsCtx { return c }
        let m = modifiers
        let mods: [String: Bool] = [
            "shift":   m.contains(.shift),
            "option":  m.contains(.option),
            "command": m.contains(.command),
            "control": m.contains(.control),
        ]
        let opener: [String: Any] = ["bundleId": self.opener]
        let dict: [String: Any] = ["url": url, "opener": opener, "modifiers": mods]
        let v = JSValue(object: dict, in: jsContext)!
        _jsCtx = v
        return v
    }
}

// MARK: - Engine

final class Engine {
    private let defaultBrowser: BrowserSpec
    private let browsers: [String: BrowserSpec]
    private let rewrites: [RewriteRule]
    private let rules: [Rule]
    private let jsContext: JSContext   // retained for slow-path fn calls

    var defaultBrowserId: String { defaultBrowser.bundleId }

    init(loaded: LoadedConfig) throws {
        self.jsContext = loaded.ctx
        let exports = loaded.exports

        // Browsers dictionary
        var browsers: [String: BrowserSpec] = [:]
        if let b = exports.objectForKeyedSubscript("browsers"),
           !b.isUndefined && !b.isNull,
           let dict = b.toDictionary() as? [String: Any] {
            for (key, val) in dict {
                browsers[key] = parseBrowser(val)
            }
        }
        self.browsers = browsers

        // Default browser
        let def = exports.objectForKeyedSubscript("default")
        guard let def = def, !def.isUndefined else {
            throw EngineError.missingDefault
        }
        self.defaultBrowser = resolveBrowser(def, browsers: browsers)
            ?? BrowserSpec(bundleId: def.toString() ?? "", args: [])

        // Rewrites
        let rewriteArr = exports.objectForKeyedSubscript("rewrite")
        self.rewrites = parseRewriteArray(rewriteArr)

        // Rules
        let rulesArr = exports.objectForKeyedSubscript("rules")
        self.rules = parseRuleArray(rulesArr, browsers: browsers)
    }

    // MARK: Hot path

    func resolve(urlString: String, opener: String, modifiers: NSEvent.ModifierFlags) -> Resolution {
        let rc = ResolveCtx(url: urlString, opener: opener, modifiers: modifiers, jsContext: jsContext)
        var current = urlString

        // Apply matching rewrites in order
        for rw in rewrites where anyMatch(rw.matchers, url: current, rc: rc) {
            current = applyRewrite(rw.rewriter, url: current, rc: rc)
            rc._invalidate()
        }

        // First matching rule wins
        for rule in rules where anyMatch(rule.matchers, url: current, rc: rc) {
            switch rule.target {
            case .browser(let b):
                return Resolution(browser: b, url: URL(string: current) ?? URL(string: urlString)!)
            case .suppress:
                return Resolution(browser: BrowserSpec(bundleId: "", args: []),
                                  url: URL(string: "about:blank")!)
            case .fn(let fn):
                if let result = fn.call(withArguments: [current, rc.jsCtx()]),
                   !result.isUndefined && !result.isNull {
                    let spec = resolveBrowser(result, browsers: browsers)
                        ?? BrowserSpec(bundleId: result.toString() ?? "", args: [])
                    return Resolution(browser: spec, url: URL(string: current) ?? URL(string: urlString)!)
                }
            }
        }

        return Resolution(browser: defaultBrowser, url: URL(string: current) ?? URL(string: urlString)!)
    }

    // MARK: Native match dispatch

    private func anyMatch(_ matchers: [Matcher], url: String, rc: ResolveCtx) -> Bool {
        for m in matchers where matches(m, url: url, rc: rc) {
            return true
        }
        return false
    }

    private func matches(_ m: Matcher, url: String, rc: ResolveCtx) -> Bool {
        switch m {
        case .regex(let re):
            return re.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) != nil
        case .domain(let hosts):
            // Extract hostname inline — avoid URLComponents allocation overhead
            guard let host = quickHost(url) else { return false }
            for h in hosts {
                if host == h || host.hasSuffix("." + h) { return true }
            }
            return false
        case .from(let apps):
            return apps.contains(rc.opener)
        case .running(let apps):
            let runs = rc.runningApps()
            return apps.contains(where: { runs.contains($0) })
        case .fn(let fn):
            return fn.call(withArguments: [url, rc.jsCtx()])?.toBool() ?? false
        }
    }

    private func applyRewrite(_ r: Rewriter, url: String, rc: ResolveCtx) -> String {
        switch r {
        case .strip(let exact, let prefixes):
            return stripParams(url, exact: exact, prefixes: prefixes)
        case .literal(let s):
            return s
        case .fn(let fn):
            return fn.call(withArguments: [url, rc.jsCtx()])?.toString() ?? url
        }
    }
}

enum EngineError: Error { case missingDefault }

// MARK: - Compilation: walk JSValue tree → native types

private func parseBrowser(_ val: Any) -> BrowserSpec {
    if let s = val as? String { return BrowserSpec(bundleId: s, args: []) }
    if let d = val as? [String: Any] {
        let id = d["id"] as? String ?? ""
        let args = d["args"] as? [String] ?? []
        return BrowserSpec(bundleId: id, args: args)
    }
    return BrowserSpec(bundleId: "", args: [])
}

private func resolveBrowser(_ v: JSValue, browsers: [String: BrowserSpec]) -> BrowserSpec? {
    if v.isString, let s = v.toString() {
        if let named = browsers[s] { return named }
        return BrowserSpec(bundleId: s, args: [])
    }
    if v.isObject, let d = v.toDictionary() as? [String: Any] {
        return parseBrowser(d)
    }
    return nil
}

private func parseRuleArray(_ arr: JSValue?, browsers: [String: BrowserSpec]) -> [Rule] {
    guard let arr = arr, !arr.isUndefined, !arr.isNull else { return [] }
    let count = Int(arr.objectForKeyedSubscript("length")?.toInt32() ?? 0)
    var out: [Rule] = []
    for i in 0 ..< count {
        guard let item = arr.atIndex(i) else { continue }
        let matchVal = item.objectForKeyedSubscript("match")
        let openVal  = item.objectForKeyedSubscript("open")
        let matchers = compileMatchers(matchVal)
        let target: Target
        if let openVal = openVal, openVal.isNull {
            target = .suppress
        } else if let openVal = openVal, openVal.isObject,
                  openVal.objectForKeyedSubscript("call") != nil,
                  openVal.isInstance(of: jsContextFunctionCtor(openVal.context)) {
            target = .fn(openVal)
        } else if let openVal = openVal, let b = resolveBrowser(openVal, browsers: browsers) {
            target = .browser(b)
        } else {
            continue
        }
        out.append(Rule(matchers: matchers, target: target))
    }
    return out
}

private func parseRewriteArray(_ arr: JSValue?) -> [RewriteRule] {
    guard let arr = arr, !arr.isUndefined, !arr.isNull else { return [] }
    let count = Int(arr.objectForKeyedSubscript("length")?.toInt32() ?? 0)
    var out: [RewriteRule] = []
    for i in 0 ..< count {
        guard let item = arr.atIndex(i) else { continue }

        // Bare strip(...) marker (no match field) — treat as "always run"
        if isMarker(item, type: "strip") {
            if let r = compileStrip(item) {
                out.append(RewriteRule(matchers: [matchAlways()], rewriter: r))
            }
            continue
        }

        let matchVal = item.objectForKeyedSubscript("match")
        let urlVal   = item.objectForKeyedSubscript("url")
        let matchers = compileMatchers(matchVal)
        let rewriter: Rewriter
        if let urlVal = urlVal, isFunction(urlVal) {
            rewriter = .fn(urlVal)
        } else if let urlVal = urlVal, let s = urlVal.toString() {
            rewriter = .literal(s)
        } else {
            continue
        }
        out.append(RewriteRule(matchers: matchers, rewriter: rewriter))
    }
    return out
}

private func compileMatchers(_ v: JSValue?) -> [Matcher] {
    guard let v = v, !v.isUndefined, !v.isNull else { return [] }
    // Array of patterns → OR
    if v.isArray {
        let count = Int(v.objectForKeyedSubscript("length")?.toInt32() ?? 0)
        var ms: [Matcher] = []
        for i in 0 ..< count {
            if let item = v.atIndex(i), let m = compileMatcher(item) { ms.append(m) }
        }
        return ms
    }
    return compileMatcher(v).map { [$0] } ?? []
}

private func compileMatcher(_ v: JSValue) -> Matcher? {
    // String → hostname pattern (NOT full URL — fixes Finicky's #1 trap)
    if v.isString, let s = v.toString() {
        return .domain([s.lowercased()])
    }
    // Marker objects
    if v.isObject {
        if let typeVal = v.objectForKeyedSubscript("__type"), !typeVal.isUndefined {
            switch typeVal.toString() {
            case "domain":
                if let arr = v.objectForKeyedSubscript("hosts")?.toArray() as? [String] {
                    return .domain(arr.map { $0.lowercased() })
                }
            case "from":
                if let arr = v.objectForKeyedSubscript("apps")?.toArray() as? [String] {
                    return .from(arr)
                }
            case "running":
                if let arr = v.objectForKeyedSubscript("apps")?.toArray() as? [String] {
                    return .running(arr)
                }
            default: break
            }
        }
        // Regex literal /.../ — compile to NSRegularExpression
        if v.isInstance(of: jsContextRegExpCtor(v.context)) {
            if let pattern = v.objectForKeyedSubscript("source")?.toString(),
               let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                return .regex(re)
            }
        }
        // Function → slow path
        if isFunction(v) { return .fn(v) }
    }
    return nil
}

private func compileStrip(_ v: JSValue) -> Rewriter? {
    guard let arr = v.objectForKeyedSubscript("params")?.toArray() as? [String] else { return nil }
    var exact = Set<String>()
    var prefixes: [String] = []
    for p in arr {
        if p.hasSuffix("*") { prefixes.append(String(p.dropLast())) }
        else { exact.insert(p) }
    }
    return .strip(exact, prefixes: prefixes)
}

private func matchAlways() -> Matcher {
    let re = try! NSRegularExpression(pattern: ".*", options: [])
    return .regex(re)
}

// MARK: - JSValue helpers

private var _regExpCache: [ObjectIdentifier: JSValue] = [:]
private var _functionCache: [ObjectIdentifier: JSValue] = [:]

private func jsContextRegExpCtor(_ ctx: JSContext?) -> JSValue {
    guard let ctx = ctx else { return JSValue() }
    let key = ObjectIdentifier(ctx)
    if let c = _regExpCache[key] { return c }
    let v = ctx.evaluateScript("RegExp")!
    _regExpCache[key] = v
    return v
}

private func jsContextFunctionCtor(_ ctx: JSContext?) -> JSValue {
    guard let ctx = ctx else { return JSValue() }
    let key = ObjectIdentifier(ctx)
    if let c = _functionCache[key] { return c }
    let v = ctx.evaluateScript("Function")!
    _functionCache[key] = v
    return v
}

private func isFunction(_ v: JSValue) -> Bool {
    return v.isInstance(of: jsContextFunctionCtor(v.context))
}

private func isMarker(_ v: JSValue, type: String) -> Bool {
    guard v.isObject else { return false }
    let t = v.objectForKeyedSubscript("__type")
    return t?.toString() == type
}

// MARK: - URL utilities (hot-path inline parsing)

// Extract hostname from a URL string without full URLComponents cost.
// Returns lowercased hostname or nil. Handles http(s)://, //, scheme:host.
@inline(__always)
private func quickHost(_ url: String) -> String? {
    var s = url
    if let r = s.range(of: "://") { s = String(s[r.upperBound...]) }
    // Trim path / query / fragment / port / userinfo
    if let i = s.firstIndex(where: { "/?#".contains($0) }) { s = String(s[..<i]) }
    if let at = s.lastIndex(of: "@") { s = String(s[s.index(after: at)...]) }
    if let colon = s.lastIndex(of: ":") { s = String(s[..<colon]) }
    return s.isEmpty ? nil : s.lowercased()
}

private func stripParams(_ url: String, exact: Set<String>, prefixes: [String]) -> String {
    guard let q = url.firstIndex(of: "?") else { return url }
    let base = String(url[..<q])
    let rest = String(url[url.index(after: q)...])
    let (qs, frag): (String, String) = {
        if let h = rest.firstIndex(of: "#") {
            return (String(rest[..<h]), String(rest[h...]))
        }
        return (rest, "")
    }()

    let kept = qs.split(separator: "&").filter { kv in
        let key = kv.split(separator: "=", maxSplits: 1).first.map(String.init) ?? String(kv)
        if exact.contains(key) { return false }
        for p in prefixes where key.hasPrefix(p) { return false }
        return true
    }

    if kept.isEmpty { return base + frag }
    return base + "?" + kept.joined(separator: "&") + frag
}

// MARK: - ResolveCtx caching invalidation

private extension ResolveCtx {
    func _invalidate() {
        // After a rewrite mutates the URL string, the ctx.url field is stale.
        // We don't currently reflect rewritten URL into the ctx object — user
        // function predicates see the post-rewrite URL via the first argument.
    }
}

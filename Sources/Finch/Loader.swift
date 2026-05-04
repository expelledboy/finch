import Foundation
import JavaScriptCore

// Loads ~/.finch.js, evaluates it in a JSContext with helpers + URL polyfill
// pre-injected, and returns the module.exports JSValue plus the context that
// owns it (must be kept alive — JSValues retain their context).

struct LoadedConfig {
    let exports: JSValue   // the user's module.exports
    let ctx: JSContext     // owns all JSValues; must outlive the engine
}

func loadConfig() -> LoadedConfig? {
    let path = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".finch.js")
    guard let source = try? String(contentsOf: path, encoding: .utf8) else {
        fputs("finch: no config at \(path.path) — create ~/.finch.js\n", stderr)
        return nil
    }

    let ctx = JSContext()!
    var lastError: String?
    ctx.exceptionHandler = { _, ex in
        let line = ex?.objectForKeyedSubscript("line").toString() ?? "?"
        let msg  = ex?.toString() ?? "unknown"
        lastError = "\(msg) (line \(line))"
        fputs("finch: js error: \(lastError ?? "")\n", stderr)
    }

    // Inject prelude (URL polyfill + helpers + module scaffolding)
    ctx.evaluateScript(JS_PRELUDE)
    if lastError != nil { return nil }

    // Evaluate user config wrapped in IIFE so module/exports are scoped
    ctx.evaluateScript(wrapUserConfig(source))
    if lastError != nil { return nil }

    guard let mod = ctx.objectForKeyedSubscript("__finchModule"),
          let exports = mod.objectForKeyedSubscript("exports"),
          !exports.isUndefined && !exports.isNull
    else {
        fputs("finch: config did not export anything (use module.exports = {...})\n", stderr)
        return nil
    }

    return LoadedConfig(exports: exports, ctx: ctx)
}

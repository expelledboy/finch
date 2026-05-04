import Cocoa

private let kInternetEventClass = AEEventClass(0x4755524C)  // 'GURL'
private let kAEGetURL           = AEEventID(0x4755524C)     // 'GURL'
private let keyDirectObject     = AEKeyword(0x2D2D2D2D)     // '----'

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var engine: Engine?
    private var statusItem: NSStatusItem?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:reply:)),
            forEventClass: kInternetEventClass,
            andEventID: kAEGetURL
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        reloadEngine()
        setupMenuBar()
        signal(SIGHUP) { _ in
            DispatchQueue.main.async { (NSApp.delegate as? AppDelegate)?.reloadEngine() }
        }

        let args = CommandLine.arguments.dropFirst()
        if let ti = args.firstIndex(of: "--test"), args.indices.contains(ti + 1) {
            testURL(String(args[ti + 1]))
            NSApp.terminate(nil)
        }
        if let bi = args.firstIndex(of: "--bench"),
           args.indices.contains(bi + 1), args.indices.contains(bi + 2) {
            bench(n: Int(args[bi + 1]) ?? 10_000, url: String(args[bi + 2]))
            NSApp.terminate(nil)
        }
    }

    // MARK: - Hot path

    @objc func handleURL(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let raw = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let engine else { return }

        let opener    = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let modifiers = NSEvent.modifierFlags

        let result = engine.resolve(urlString: raw, opener: opener, modifiers: modifiers)
        if result.browser.bundleId.isEmpty { return }   // suppressed (open: null)
        open(url: result.url, spec: result.browser)
    }

    private func open(url: URL, spec: BrowserSpec) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: spec.bundleId) else {
            fputs("finch: browser not found: \(spec.bundleId)\n", stderr)
            NSWorkspace.shared.open(url)
            return
        }
        let cfg = NSWorkspace.OpenConfiguration()
        if !spec.args.isEmpty { cfg.arguments = spec.args }
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: cfg, completionHandler: nil)
    }

    // MARK: - Helpers

    private func reloadEngine() {
        guard let loaded = loadConfig() else { return }
        do { engine = try Engine(loaded: loaded) }
        catch { fputs("finch: engine init failed: \(error)\n", stderr) }
    }

    private func testURL(_ raw: String) {
        guard let engine else { print("finch: no config loaded"); return }
        let result = engine.resolve(urlString: raw, opener: "test.app", modifiers: [])
        print("URL:     \(raw)")
        print("Final:   \(result.url)")
        print("Browser: \(result.browser.bundleId)")
        if !result.browser.args.isEmpty { print("Args:    \(result.browser.args.joined(separator: " "))") }
    }

    private func bench(n: Int, url: String) {
        guard let engine else { print("finch: no config loaded"); return }
        for _ in 0 ..< min(n / 10, 1_000) {
            _ = engine.resolve(urlString: url, opener: "com.tinyspeck.slackmacgap", modifiers: [])
        }
        let start = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
        for _ in 0 ..< n {
            _ = engine.resolve(urlString: url, opener: "com.tinyspeck.slackmacgap", modifiers: [])
        }
        let elapsed = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) - start
        let nsPerOp = elapsed / UInt64(n)
        let usPerOp = Double(elapsed) / Double(n) / 1_000
        print("Benchmark: \(n) iterations")
        print("Total:     \(elapsed / 1_000_000)ms")
        print("Per-op:    \(nsPerOp)ns  (\(String(format: "%.2f", usPerOp))µs)")
        let r = engine.resolve(urlString: url, opener: "com.tinyspeck.slackmacgap", modifiers: [])
        print("URL:       \(url)")
        print("Browser:   \(r.browser.bundleId)")
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.title = "🐦"
        let menu = NSMenu()
        menu.addItem(withTitle: "Reload Config",    action: #selector(reloadConfig),    keyEquivalent: "r")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Finch",       action: #selector(NSApp.terminate), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc private func reloadConfig() { reloadEngine() }
}

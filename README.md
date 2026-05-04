# Finch

A tiny, fast macOS browser router. Set it as your default browser; it routes
each URL to the right browser based on rules in `~/.finch.js`.

- **~700 LOC** Swift + a 1.5KB embedded JS URL polyfill
- **~5µs** hot-path latency on the common case (well under perceptible)
- Native `JavaScriptCore`, no bundler, no transpiler, no Electron
- Config is real JavaScript — simple cases look like data, full power available

## Why

Existing macOS browser pickers either lack power (Browserosaurus, Bumpr) or
carry significant complexity (Finicky ships ~2,900 LOC plus a Babel/esbuild/goja
config pipeline). Finch keeps the powerful parts of Finicky's design (graduated
match types, opener context, URL rewriting) but compiles config helpers to
native Swift code so the hot path stays in Swift, not JS.

## How Finch compares

|                          | **Finch**     | Finicky    | Velja  | Choosy | Browserosaurus |
|--------------------------|---------------|------------|--------|--------|----------------|
| Source LOC               | **~700**      | ~2,900     | closed | closed | ~4,200         |
| Hot-path latency         | **~5 µs**     | unknown    | —      | —      | —              |
| Memory footprint         | ~17 MB        | ~30 MB     | —      | —      | ~150 MB        |
| Programmable rules       | ✅            | ✅         | 🚧 URL only | ❌     | ❌             |
| Modern ES2020+ in config | ✅            | ❌ (ES5.1) | —      | —      | —              |
| Caller app routing       | ✅            | ✅         | ✅     | ✅     | ❌             |
| URL rewriting            | ✅            | ✅         | ✅     | ❌     | ❌             |
| Tracking-strip helper    | ✅            | 🚧 manual  | ✅     | ❌     | ❌             |
| Bundler / transpiler     | none          | Babel + esbuild + goja | — | — | Vite + Forge |
| Open source              | ✅ MIT        | ✅ MIT     | ❌     | ❌     | ✅ (archived)  |
| Free                     | ✅            | ✅         | $8     | $10    | ✅             |
| Actively maintained      | ✅            | ✅         | ✅     | ✅     | ❌ (Aug 2025)  |

Full feature matrix across all 18 alternatives we evaluated:
[COMPARISON.md](COMPARISON.md). Finch's own implementation status and roadmap:
[FEATURES.md](FEATURES.md).

## Install

Requires macOS 13+ and Xcode Command Line Tools (`xcode-select --install`).

**Via Homebrew** (recommended):

```sh
brew install --cask expelledboy/finch/finch
```

The cask builds from source on your machine — no Developer ID needed, no
Gatekeeper warnings. See [docs/homebrew.md](docs/homebrew.md) for how the
distribution works and the release process.

**From source:**

```sh
git clone https://github.com/expelledboy/finch
cd finch
make run
```

Then launch Finch (🐦 in your menu bar), open **System Settings → Desktop &
Dock → Default web browser** and select Finch. Edit `~/.finch.js` to define
your rules — see [`examples/finch.example.js`](examples/finch.example.js).

## Configuration

Drop a JavaScript file at `~/.finch.js`. See [`examples/finch.example.js`](examples/finch.example.js).

```js
module.exports = {
  default: "zen",

  browsers: {
    zen:    "app.zen-browser.zen",
    prisma: "com.talon-sec.Work",
    chrome: { id: "com.google.Chrome", args: ["--profile-directory=Work"] },
  },

  // All matching rewrites apply, in order
  rewrite: [
    strip("utm_*", "fbclid", "gclid"),
  ],

  // First matching rule wins
  rules: [
    { match: domain("paymentology.atlassian.net", "datadoghq.com", "zoom.us"),
      open: "prisma" },

    { match: /github\.com\/(paymentology|tutuka)\//, open: "prisma" },

    // Full power: any predicate function works
    { match: (url, ctx) => ctx.modifiers.option, open: "zen" },
  ],
};
```

### Match types

| Syntax | Matches | Notes |
|---|---|---|
| `"example.com"` | hostname, exactly or as subdomain | Most common — bare strings are hostname patterns, not full URLs |
| `domain("a.com", "b.com")` | any of these hostnames | Compiled to a single fast check |
| `from("com.tinyspeck.slackmacgap")` | URL was opened by this app | Caller bundle ID |
| `running("us.zoom.xos")` | this app is currently running | |
| `/regex/` | regex against full URL | For path-specific rules |
| `(url, ctx) => bool` | anything | Slow path (~5µs extra), full power |

The `ctx` argument has `ctx.url`, `ctx.opener.bundleId`, and `ctx.modifiers.{shift,option,command,control}`.

### Browser targets

| Syntax | Means |
|---|---|
| `"zen"` | Look up `zen` in `browsers` dict |
| `"app.zen-browser.zen"` | Direct bundle ID |
| `{ id: "com.google.Chrome", args: ["--incognito"] }` | Bundle ID with launch args |
| `(url, ctx) => "zen"` | Dynamic target |
| `null` | Suppress — do nothing |

### Rewrite rules

| Syntax | Effect |
|---|---|
| `strip("utm_*", "fbclid")` | Remove these query params (supports `*` suffix) |
| `{ match: ..., url: "..." }` | Replace URL when match hits |
| `{ match: ..., url: (u, ctx) => ... }` | Transform URL via JS |

A `URL` constructor is available inside predicates and rewrites for parsing.

## Commands

```sh
make build                          # build Finch.app
make run                            # build + register + launch
make test URL="https://..."         # dry-run a URL through the rules
make clean
```

To reload config after editing `~/.finch.js`:

```sh
kill -HUP $(pgrep -f Finch.app/Contents/MacOS/Finch)
```

Or use the menu bar icon → Reload Config.

The binary also has `--bench N <url>` for in-process resolve benchmarking.

## Performance

Measured on Apple Silicon, macOS 15, release build, 100k iterations.

| Path | Latency |
|---|---|
| Default fallback (no rule match) | 5.2µs |
| `domain()` match | 5.4µs |
| Subdomain match | 4.9µs |
| Regex match | 4.5µs |
| Tracking strip + match | 8.7µs |
| User function predicate | ~10µs |

For comparison: macOS dispatching the Apple Event from the originating app to
Finch takes ~1–5ms. Finch's contribution to click-to-browser latency is in the
noise.

The trick: `domain()`, `from()`, `strip()` etc. return marker objects like
`{__type: "domain", hosts: [...]}` that Swift recognizes at config load and
compiles to native `NSRegularExpression` / `Set<String>`. The Swift→JS bridge
is only crossed for user-written `(url, ctx) => ...` predicates.

## Architecture

| File | LOC | Responsibility |
|---|---|---|
| `Sources/Finch/main.swift` | 6 | Bootstrap |
| `Sources/Finch/AppDelegate.swift` | 112 | Apple Event handler, hot path entry, `NSWorkspace.open` |
| `Sources/Finch/Loader.swift` | 46 | Read `~/.finch.js`, evaluate via JSC, return module.exports |
| `Sources/Finch/Helpers.swift` | 101 | Embedded JS prelude: URL polyfill + `domain`/`from`/`strip` helpers |
| `Sources/Finch/Engine.swift` | 442 | Marker compilation + native hot-path resolver |

## License

MIT — see [LICENSE](LICENSE).

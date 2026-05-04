# Features

The complete feature space of macOS/Windows/Linux browser pickers, with Finch's
implementation status. This doubles as a roadmap — features marked ⬜ are
candidates for future work; features marked ❌ are explicit non-goals.

**Legend**
- ✅ Shipped
- 🚧 Partial — works but with limitations (see notes)
- ⬜ Planned
- ❌ Out of scope — incompatible with the project's design goals

---

## 1. Routing Targets

| Feature | Status | Notes |
|---|---|---|
| Default browser fallback | ✅ | `default:` field |
| Multiple browser targets | ✅ | `browsers` dict + `rules` |
| Browser profile support | ✅ | Via `args: ["--profile-directory=Work"]` or `-P` |
| Private/incognito routing | ✅ | Via launch args |
| Native app deep-link routing | ✅ | Bundle ID can target any app; rewrite URLs to `slack://`, `zoommtg://`, etc. |
| `mailto:` routing | ✅ | Registered in `Info.plist`, routed by same rules engine |
| `tel:` routing | ⬜ | Add scheme to `Info.plist`, routes through engine for free |
| Arbitrary custom protocol routing | 🚧 | We register `http/https/mailto`; rewriting to other protocols works, but Finch can't be the *handler* for them without plist changes |
| Open in multiple browsers at once | ⬜ | Engine returns one target today; would need an array of targets |
| Per-rule "do nothing" / suppress | ✅ | `open: null` |

## 2. URL Matching

| Feature | Status | Notes |
|---|---|---|
| Bare string → hostname match | ✅ | `"example.com"` matches host or subdomain |
| Wildcard hostname matching | ✅ | `domain("a.com", "b.com")` |
| Full URL regex matching | ✅ | `/pattern/` literal in JS |
| Predicate/function matching | ✅ | `(url, ctx) => bool` — full power |
| Caller app detection | ✅ | `from("com.tinyspeck.slackmacgap")`, `ctx.opener.bundleId` |
| Bundle ID matching | ✅ | Native, no string parsing |
| Modifier key detection | ✅ | `ctx.modifiers.{shift,option,command,control}` |
| Running-app detection | ✅ | `running("us.zoom.xos")` — lazily evaluated |
| Rule priority control | ✅ | Top-down array, first match wins |
| Window title matching | ⬜ | Requires Accessibility permission; would expose `ctx.opener.windowTitle` |
| Focus mode / system state matching | ⬜ | macOS Focus Filter integration |
| OR semantics within a rule | ✅ | Pass an array to `match` |

## 3. URL Processing

| Feature | Status | Notes |
|---|---|---|
| URL rewriting / transformation | ✅ | `rewrite` array, all matching apply in order |
| Tracking parameter stripping | ✅ | `strip("utm_*", "fbclid")` — native Swift, fast |
| Force HTTPS upgrade | ✅ | Via JS rewrite or string replace |
| Browser launch args | ✅ | Per-browser `args` field |
| Short URL expansion | ⬜ | HTTP redirect chase before matching (Finicky has this) |
| SafeLinks / corp link deobfuscation | ⬜ | Outlook/Teams URL unwrapping; trivial as a built-in helper |
| URL preview / edit before open | ❌ | Out of scope — Finch is silent by design |
| URL parsing in predicates | ✅ | 1.5KB `URL` polyfill injected into JS context |

## 4. Configuration

| Feature | Status | Notes |
|---|---|---|
| Text config file | ✅ | `~/.finch.js` — real JavaScript, version-controllable |
| Modern JS in config (ES2020+) | ✅ | Arrow fns, destructuring, optional chaining — all native in JSC |
| Programmable rules | ✅ | Full JS predicates with lazy ctx |
| Import/export rules | ✅ | It's a file — copy it |
| URL tester / debugger | ✅ | `finch --test "https://..."` |
| Hot reload | ✅ | `kill -HUP $(pgrep Finch)` or menu bar action |
| Marker-compiled helpers | ✅ | `domain()`, `from()`, `strip()` compile to native — see [README perf](README.md#performance) |
| GUI rule builder | ❌ | Out of scope — text config is the primary interface |
| Request logging | ⬜ | Useful for debugging "why did this URL go there" |
| Config validation / dry run | 🚧 | `--test` validates routing; no schema validation step |
| Multiple config files / includes | ⬜ | `require()` support would let users split work/personal |
| MDM / enterprise deployment | ⬜ | System-wide config search path (`/Library/Application Support/Finch/`) |

## 5. UX & Interface

| Feature | Status | Notes |
|---|---|---|
| Menu bar icon | ✅ | 🐦 — Reload Config, Quit |
| Background-only operation | ✅ | No Dock icon, `LSUIElement` |
| Hot reload via signal | ✅ | SIGHUP |
| Auto-detect installed browsers | ⬜ | Suggest bundle IDs from `LSCopyAllRoleHandlersForContentType` |
| Prompt-every-time / interactive picker | ⬜ | Optional fallback when rules don't decide |
| Quick default-switch shortcut | ⬜ | Global hotkey to flip a "force browser X" mode |
| Frequency-based browser ranking | ❌ | Belongs in a picker UI, which we don't ship |
| Browser extension companion | ⬜ | For intercepting links inside browsers |
| Open in background (no focus steal) | ⬜ | `NSWorkspace.OpenConfiguration.activates = false` |
| Desktop notifications | ⬜ | "Routed X to Y" — useful for debugging, noise in steady state |
| Auto-update | ❌ | Out of scope; install via git pull + `make build` |

## 6. Platform & Licensing

| Feature | Status | Notes |
|---|---|---|
| macOS 13+ | ✅ | |
| Windows | ❌ | macOS-only by design (different APIs entirely) |
| Linux | ❌ | macOS-only by design |
| Open source | ✅ | MIT |
| Free | ✅ | |
| Code-signed | 🚧 | Ad-hoc signed; no Developer ID / notarization yet |

## 7. Power Features

| Feature | Status | Notes |
|---|---|---|
| Native opener context (bundle ID, modifiers, running apps) | ✅ | First-class in `ctx` |
| URL polyfill in JS predicates | ✅ | `new URL(href).hostname` works |
| Firefox Multi-Account Containers | 🚧 | Achievable via rewrite to `ext+container:` URL; no built-in helper yet |
| Arc Spaces routing | ⬜ | Arc has URL scheme support; would need a dedicated helper |
| Apple Shortcuts integration | ⬜ | Expose actions for "set default browser" / "route URL" |
| Handoff / Share menu integration | 🚧 | Apple Event handler catches URLs from anywhere; no Share extension |
| Safari Web App targeting | ⬜ | Route specific URLs to pinned PWAs |
| `finch://` URI scheme to invoke from scripts | ⬜ | `open finch://route/https://...` for AppleScript/CLI |
| Open from clipboard | ⬜ | Menu bar action: route current pasteboard URL |
| Privacy sandboxing emphasis | ❌ | Not the project's positioning |

## Architectural advantages

These aren't traditional "features" but are differentiators worth tracking:

| Property | Status | Notes |
|---|---|---|
| Sub-10µs hot path | ✅ | 5µs common case, 8µs with rewrites |
| ~700 LOC total | ✅ | Compare: Finicky ~2,900, Browserosaurus ~4,200 |
| No bundler / transpiler | ✅ | Native JSC evaluates ES2020+ directly |
| Marker-object compilation | ✅ | Helpers return data, not functions; Swift compiles to native |
| Lazy `ctx` construction | ✅ | 5.7µs object built at most once per resolve |
| First-match-wins ordering | ✅ | No surprising precedence rules |
| Persistent background process | ✅ | No cold-start cost on hot path |

---

## Roadmap priority

If we ship the planned features in order of effort × impact:

**Tier 1 — Cheap, high value**
1. `tel:` scheme registration (one-line plist change)
2. Short URL expansion (Finicky parity, ~30 LOC)
3. SafeLinks/Outlook deobfuscation helper (~20 LOC)
4. Auto-detect installed browsers (CLI helper for config writing)
5. Window title in `ctx.opener` (Accessibility permission required)

**Tier 2 — Worth doing**
6. `finch://` URI scheme for scripting
7. Open from clipboard menu action
8. Optional prompt-every-time fallback
9. Multiple config files via `require()`
10. Open in background flag

**Tier 3 — Larger commitments**
11. Browser extension companion
12. Apple Shortcuts integration
13. Developer ID signing + notarization
14. Open in multiple browsers at once
15. MDM-friendly system-wide config

**Explicit non-goals (won't do)**
- GUI rule builder (text config is the design)
- Cross-platform (Windows/Linux are different problems)
- Auto-update (use git)
- Frequency-based picker ranking (no picker UI)
- Privacy sandboxing positioning (not the pitch)

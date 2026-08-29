# Comparison: Finch vs Alternatives

Comprehensive feature comparison across every macOS, Windows, and Linux browser
picker we identified. Source data: research conducted during Finch's design
phase (parallel agents reviewing each tool's docs, source code, and release
notes).

**Legend:** ✅ Yes  ❌ No  🚧 Partial  ❓ Unknown / undocumented  — N/A on this platform

**Column key**

*macOS:* **Fch** Finch · **Fin** Finicky · **Vel** Velja · **Cho** Choosy · **OpI** OpenIn · **BrF** BrowserFairy · **Bro** Browserosaurus · **Bmp** Bumpr · **Swb** Switchbar · **BPe** BrowserPicker (ealeksandrov)

*Windows:* **BRo** BrowseRouter · **DaT** DanTup/BrowserSelector · **mBP** mortenn/BrowserPicker · **Hrl** Hurl · **BSe** BrowserSelect · **x01** x011/browser-router

*Linux:* **Jun** Junction · **xdg** xdg-open + mimeapps

---

## 1. Routing Targets

| Feature | Fch | Fin | Vel | Cho | OpI | BrF | Bro | Bmp | Swb | BPe | BRo | DaT | mBP | Hrl | BSe | x01 | Jun | xdg |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Default browser fallback | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🚧 | ✅ |
| Multiple browser targets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🚧 |
| Browser profile support | ✅ | 🚧 | ✅ | ✅ | 🚧 | ❓ | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | 🚧 | ❌ | ✅ | 🚧 |
| Private/incognito routing | ✅ | ❓ | ✅ | ✅ | ✅ | ❓ | ❌ | ❌ | ❓ | ❌ | ❓ | ❓ | ✅ | ✅ | ✅ | ❌ | ❓ | ❓ |
| Native app deep-link routing | ✅ | ✅ | ✅ | 🚧 | ✅ | ❓ | ❌ | 🚧 | ✅ | ❌ | 🚧 | 🚧 | ❓ | ❓ | ❌ | ❌ | ✅ | 🚧 |
| `mailto:` routing | ✅ | ❌ | ❓ | ❓ | ✅ | ❓ | ❓ | ✅ | ✅ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❌ | ✅ | ✅ |
| `tel:` routing | ⬜ | ❌ | ❓ | ❓ | ✅ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❌ | 🚧 | ✅ |
| Arbitrary custom protocol | 🚧 | 🚧 | 🚧 | 🚧 | ✅ | ❓ | ❓ | ❓ | ❓ | ❌ | 🚧 | 🚧 | ❓ | ❓ | ❓ | ❌ | ✅ | ✅ |
| Open in multiple browsers at once | ⬜ | ❌ | ❌ | ✅ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Per-rule suppress (do nothing) | ✅ | ✅ | ❓ | ❓ | ❓ | ❌ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

## 2. URL Matching

| Feature | Fch | Fin | Vel | Cho | OpI | BrF | Bro | Bmp | Swb | BPe | BRo | DaT | mBP | Hrl | BSe | x01 | Jun | xdg |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Exact string URL matching | ✅ | ✅ | ✅ | ✅ | ✅ | 🚧 | ❌ | 🚧 | ❓ | 🚧 | 🚧 | 🚧 | 🚧 | ✅ | ❓ | ❓ | ❌ | ❌ |
| Wildcard hostname matching | ✅ | ✅ | ✅ | ✅ | ✅ | ❓ | ❌ | ❓ | ❓ | ❌ | ✅ | ✅ | 🚧 | ❌ | 🚧 | ✅ | ❌ | ❌ |
| Regex URL matching | ✅ | ✅ | ❓ | ✅ | ✅ | ❓ | ❌ | ❓ | ❓ | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Predicate / function matching | ✅ | ✅ | 🚧 | ❌ | ✅ | ❓ | ❌ | ❌ | ❓ | 🚧 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Caller app detection | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❓ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🚧 |
| Bundle ID / process name matching | ✅ | ✅ | ✅ | 🚧 | 🚧 | ❓ | ❌ | ❌ | ❓ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | — | — |
| Window title matching | ⬜ | ✅ | ❌ | ❌ | ❌ | ❓ | ❌ | ❌ | ❓ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Focus mode / system state | ⬜ | ✅ | ✅ | ❓ | ✅ | ❓ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Modifier key detection at click | ✅ | ✅ | ❌ | ❌ | 🚧 | ❓ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ❌ | ❓ | ✅ | ❌ | ❌ | ❌ |
| Rule priority control | ✅ | ✅ | ❓ | ✅ | ✅ | ❓ | ❌ | ❓ | ❓ | ❓ | ✅ | 🚧 | ❓ | ✅ | ❓ | 🚧 | — | 🚧 |

## 3. URL Processing

| Feature | Fch | Fin | Vel | Cho | OpI | BrF | Bro | Bmp | Swb | BPe | BRo | DaT | mBP | Hrl | BSe | x01 | Jun | xdg |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| URL rewriting / transformation | ✅ | ✅ | ✅ | ❌ | ✅ | ❓ | ❌ | ❌ | ❓ | ❌ | ✅ | ❌ | 🚧 | ❌ | ❌ | ❌ | ✅ | ✅ |
| Tracking parameter stripping | ✅ | 🚧 | ✅ | ❌ | ✅ | ❓ | ❌ | ❌ | ✅ | ❌ | 🚧 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Force HTTPS upgrade | ✅ | 🚧 | ✅ | ❌ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | 🚧 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Browser launch args | ✅ | ✅ | ❓ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ✅ | ✅ | ❓ | ❓ | ❓ | ❌ | ✅ | ✅ |
| Short URL expansion | ⬜ | ✅ | ✅ | ✅ | ❓ | ❓ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | ❓ | ❌ | ❌ | ❌ | ❌ |
| SafeLinks / corp link deobfuscation | ⬜ | 🚧 | ❓ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| URL preview / edit before open | ❌ | ❌ | 🚧 | ✅ | ❓ | ❓ | ❌ | ❌ | 🚧 | ❌ | ❌ | ❌ | ✅ | ❓ | ❌ | ❌ | ✅ | ❌ |
| URL parsing helpers in predicates | ✅ | ✅ | ✅ | ❌ | ✅ | ❓ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

## 4. Configuration

| Feature | Fch | Fin | Vel | Cho | OpI | BrF | Bro | Bmp | Swb | BPe | BRo | DaT | mBP | Hrl | BSe | x01 | Jun | xdg |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| GUI rule builder | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | 🚧 | 🚧 | ✅ | ❌ | ❌ |
| Text / structured config file | ✅ | ✅ | 🚧 | 🚧 | ❓ | ❓ | ❌ | ❌ | ❓ | ✅ | ✅ | ✅ | ✅ | ✅ | ❓ | ✅ | 🚧 | ✅ |
| Scripting / programmable rules | ✅ | ✅ | ✅ | ✅ | ✅ | ❓ | ❌ | ❌ | ✅ | 🚧 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | 🚧 | ✅ |
| Modern JS in config | ✅ | ❌ | ❓ | — | ❓ | — | — | — | — | — | — | — | — | — | — | — | — | — |
| Import / export rules | ✅ | ❌ | ✅ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | 🚧 |
| URL tester / debugger | ✅ | ✅ | ✅ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | 🚧 |
| Hot reload | ✅ | ✅ | ❓ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ✅ |
| Request logging | ⬜ | ✅ | ✅ | ❓ | ✅ | ❓ | ❌ | ❌ | ❓ | ❌ | ✅ | ❌ | ❓ | ❓ | ❌ | ❌ | ❌ | ❌ |

## 5. UX & Interface

| Feature | Fch | Fin | Vel | Cho | OpI | BrF | Bro | Bmp | Swb | BPe | BRo | DaT | mBP | Hrl | BSe | x01 | Jun | xdg |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Menu bar / system tray icon | ✅ | ✅ | ✅ | ✅ | ✅ | ❓ | ❓ | ✅ | ❓ | ❌ | ❌ | ❌ | ❓ | ❓ | ❓ | ❌ | ❌ | ❌ |
| Background-only operation | ✅ | ✅ | ❓ | ❓ | ❓ | ❓ | ❌ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❓ | ❌ |
| Prompt-every-time mode | ⬜ | ❌ | ✅ | ✅ | ✅ | ❓ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| Hotkey to select browser in prompt | — | ❌ | ✅ | ✅ | 🚧 | ❓ | ❓ | ✅ | ❓ | ❌ | ❌ | ❌ | ✅ | ❓ | ✅ | ❌ | 🚧 | ❌ |
| Quick default-switch shortcut | ⬜ | ❌ | ✅ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ❓ | ❓ | ❌ | ❌ | ❌ | ✅ |
| Browser extension companion | ⬜ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | 🚧 | ❌ | ❌ | ✅ | ❌ |
| Auto-detect installed browsers | ⬜ | ❓ | ✅ | ✅ | ✅ | ❓ | ✅ | ✅ | ✅ | ❌ | ❓ | ❓ | ✅ | ❓ | ✅ | ✅ | ✅ | ✅ |
| Open in background (no focus steal) | ⬜ | ✅ | ❓ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ❌ |

## 6. Platform & Licensing

| Feature | Fch | Fin | Vel | Cho | OpI | BrF | Bro | Bmp | Swb | BPe | BRo | DaT | mBP | Hrl | BSe | x01 | Jun | xdg |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| macOS | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Windows | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Linux | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Open source | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Free | ✅ | ✅ | ❌ | ❌ | ❌ | ❓ | ✅ | ❌ | 🚧 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Actively maintained | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ❓ | ✅ | ❌ | ✅ | ✅ | ❓ | ✅ | ✅ | ✅ |

## 7. Power Features

| Feature | Fch | Fin | Vel | Cho | OpI | BrF | Bro | Bmp | Swb | BPe | BRo | DaT | mBP | Hrl | BSe | x01 | Jun | xdg |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Firefox Multi-Account Containers | 🚧 | ❓ | ✅ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ❓ | ❓ | ❓ | ❓ | ❓ | ❌ | ❓ | ❓ |
| Apple Shortcuts integration | ⬜ | ❓ | ✅ | ✅ | ✅ | ❓ | ❌ | ❌ | ✅ | ❌ | — | — | — | — | — | — | — | — |
| Handoff / Share menu integration | 🚧 | ❓ | ✅ | ✅ | ✅ | ❓ | ❌ | ❌ | ✅ | ❌ | — | — | — | — | — | — | — | — |
| Running-app state detection | ✅ | ✅ | ❓ | ❓ | ✅ | ❓ | ❌ | ❌ | ❓ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| URI scheme to invoke (e.g. `finch://`) | ⬜ | ❓ | ✅ | ✅ | ❓ | ❓ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Open from clipboard | ⬜ | ❓ | ✅ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | ❓ | ❌ | ❓ | ❓ | ❌ | ❌ | ❌ | ❌ |
| Spotlight integration | ⬜ | ❓ | ✅ | ❓ | ❓ | ❓ | ❌ | ❌ | ❓ | ❌ | — | — | — | — | — | — | — | — |
| Modern JS engine (ES2020+) | ✅ | ❌ | ❓ | — | ❓ | — | — | — | — | — | — | — | — | — | — | — | — | — |
| Code-signed installer | 🚧 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❓ | ✅ | ❓ | ✅ | ❓ | ❓ | ❓ | ✅ | — |

---

## Architectural metrics

These differentiate Finch but aren't really "features" — they're properties of
the implementation that affect maintainability, performance, and trust.

| Property | Finch | Finicky | Browserosaurus | Velja | Choosy |
|---|---|---|---|---|---|
| Source LOC | **~650** | ~2,900 | ~4,200 | closed | closed |
| Languages used | Swift + JS | Go + ObjC + TS | TS (Electron) | unknown | unknown |
| Binary size | ~500 KB | ~15 MB | ~150 MB | unknown | unknown |
| Memory footprint | ~17 MB | ~30 MB | ~150 MB | unknown | unknown |
| Cold start (process launch) | ~480 ms | ~700 ms | ~1.5 s | unknown | unknown |
| Hot path (resolve a URL) | **~5 µs** | unknown | unknown | unknown | unknown |
| Bundler / transpiler required | none | Babel + esbuild + goja | Vite + Forge | unknown | unknown |
| Config file format | JS (native ES2020+) | JS (ES5.1) | JSON | none (GUI) | none (GUI) |
| Browser interception API | `NSAppleEventManager` | `NSAppleEventManager` | Electron wrapper | unknown | unknown |

**On the LOC row:** Finch's figure is code only — comments and blank lines
excluded, reproducible with `make loc` (845 lines total, 648 of them code). The
Finicky and Browserosaurus figures are raw line counts and have not been
re-measured the same way, so this row reads more favourably to Finch than a
like-for-like count would. Treat it as an order-of-magnitude difference, not a
precise ratio.

---

## Sources

Research conducted via parallel agents reviewing each tool's GitHub README,
released source code, official documentation, and changelogs. Numbers for Finch
are measured locally (`make test` and `--bench`); numbers for other tools are
either documented or from source inspection. `❓` means the tool may support the
feature but it isn't documented or wasn't found during research.

For Finch's own implementation status and roadmap, see [FEATURES.md](FEATURES.md).

# Architecture and design decisions

Why Finch is built the way it is. This is the rationale a change should be
argued against — implementation status lives in [FEATURES.md](../FEATURES.md),
and positioning against alternatives in [COMPARISON.md](../COMPARISON.md).

## The design goal, stated so it can fail

Match the expressive power of Finicky — the established macOS browser router —
while staying small enough to read in a sitting: roughly 650 lines of Swift
(`make loc`), a hot path budgeted under 10µs, and a ~17 MB resident footprint.
The method is to compile config helpers to native Swift at load time instead of
running a JavaScript bundler pipeline at all.

10µs is the budget, not the measurement — the measured figure is ~5µs, reported
with its method in README.md § Performance. The budget is what a change is
allowed to spend; the measurement is what it currently costs.

If a change makes the config more expressive but pushes work onto the hot path,
it is working against the goal.

## Key decisions

**Native JavaScriptCore, not a bundled JavaScript engine.** Finicky embeds
goja, a JavaScript interpreter written in Go, and needs Babel (a transpiler that
rewrites modern JavaScript into an older dialect) and esbuild (a bundler) to
feed it a dialect it can run — a stack it carries because it targets more than
one platform. JavaScriptCore is Apple's JavaScript engine, ships with macOS,
already speaks ES2020+, and costs nothing to link — which removes the transpile
and bundle stages entirely. The price is that
Finch is macOS-only, accepted deliberately.

**Marker-object helpers, not callbacks.** `domain()`, `from()`, `strip()` and
`running()` return plain data objects rather than functions. `Engine.swift`
walks those markers once at config load and compiles them to native Swift —
`NSRegularExpression`, `Set<String>` — so matching never re-enters JavaScript.
The JS bridge is crossed only for predicates the user wrote as functions, which
is the explicit slow path.

The reason data beats a function here is that the cost being avoided is the
*call*, not the compilation. A callback — however well written, however cached —
must be entered through the JavaScript bridge once per URL, and that crossing
dominates a match that would otherwise be a native regex or set lookup. A marker
object is inspected once, at config load, and leaves behind Swift data
structures with no JavaScript left in the path at all. This is the single
decision the performance claim rests on.

**A JavaScript config file (`~/.finch.js`), not TOML or JSON.** Routing rules
are compositional: users want to build a matcher out of other matchers, share a
browser definition between rules, and compute a rewrite. Data formats force
that logic into a bespoke mini-language. Real JavaScript gives it away free, and
the marker-object decision above keeps the cost off the hot path.

**macOS-only by design.** URL interception, default-browser registration and
app identity are entirely different problems on Windows and Linux. Supporting
them would mean an abstraction layer over the one thing this program does.

**Text config only.** No GUI rule builder, no picker window, no auto-update.
The text file is the interface, not a fallback for one.

## Explicit non-goals

Each of these is a decision, not a gap. Reopening one needs an argument against
the reason given.

| Not doing | Because |
|---|---|
| GUI rule builder | The text config is the design, not a concession |
| Windows or Linux support | Different APIs entirely; see "macOS-only" above |
| Auto-update | Installation is `brew upgrade` or `git pull` — see [homebrew.md](homebrew.md) |
| Frequency-based browser ranking — ordering the browser choices by how often each is picked | The ordering only means something in a picker window, which Finch deliberately does not ship |
| Positioning Finch as a privacy tool | Tracking-parameter stripping is a feature, not the pitch |

## Platform behaviour this depends on

Facts about macOS that the bundle configuration encodes, each learned by being
bitten. Not an exhaustive catalogue — add to it when the next one costs you a
day. Changing `Info.plist` without knowing these will break things quietly.

**Default-browser candidacy comes from `CFBundleURLTypes` plus
`NSUserActivityTypeBrowsingWeb`, not from `CFBundleDocumentTypes`.** Finch
claims the `http`, `https` and `mailto` URL schemes and nothing else. It used to
also claim the HTML *document type*, which made `open foo.html` fail with
"Finch cannot open files in the 'HTML Document' format" — Finch is a router, it
has no renderer. Dropping that claim in v0.1.1 fixed the dialog and did not
affect default-browser candidacy, because the two come from different plist
keys. Opening local HTML files is a separate binding the user owns, via Finder's
"Open with → Change All" or `duti -s <bundle id> public.html all`.

**A stale handler preference survives a Launch Services database rebuild.**
Launch Services is the macOS subsystem that decides which app opens a given URL
scheme or file type, the latter identified by a Uniform Type Identifier (UTI)
such as `public.html`. `lsregister -kill -r` rebuilds the on-disk database but leaves an
in-memory handler map inside `lsd`, the Launch Services daemon, which continues
to serve the old answer. `lsd` has to be killed as well before the rebuild takes
effect. Symptom: a URL scheme or file type keeps opening the wrong app no matter
how many times you re-register.

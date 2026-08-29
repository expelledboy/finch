# Finch — agent orientation

Finch is a macOS browser router: it registers as the default browser and sends
each URL to a browser chosen by rules in the user's `~/.finch.js`. Swift plus
JavaScriptCore, no bundler. `make loc` prints the current size (code lines,
comments excluded — that is the figure quoted in README.md and COMPARISON.md).

**This file is mostly an index.** It exists so you can find out what has already
been decided before deciding it again. Nothing here is copied from the documents
it points at; follow the pointer and read the source. The one exception is the
last section, which holds facts that have no document of their own yet — when
one of those grows past a few lines, move it into `docs/` and leave a pointer.

**Maintaining it:** when you add a document, a directory, or a piece of the
system that lives outside this repository, add a row below. A catalogue that
silently goes stale is worse than none, because it reads as complete.

**Only point at committed files.** `.claude/` is in `.gitignore`, so anything
there is invisible to a fresh clone and to any agent but the one that wrote it.
Working notes may live there; nothing another reader must have may. If a scratch
file is holding a fact worth keeping, move the fact into `docs/` or this file
first.

## Read before you act

| Before you… | Read | It already settles |
|---|---|---|
| cut a release, bump a version, change how Finch is distributed | `docs/homebrew.md` | the two-repo tap layout, why the cask builds from source on the user's machine rather than shipping a binary, and the exact release order — the bundle version is bumped **before** tagging, because the cask builds from the tag's tarball |
| add a feature, or check whether one exists | `FEATURES.md` | per-feature status, including the ❌ rows that are deliberate non-goals rather than gaps |
| make a claim about Finch versus an alternative, or quote a number | `COMPARISON.md` | 18 evaluated alternatives, the sources behind each figure, and the caveat on how the line-count row was measured |
| change the architecture, or ask "why JavaScriptCore", "why marker objects" | `docs/architecture.md` | the stated design goal, each key decision with its rationale, the explicit non-goals and the reason behind each, and the macOS platform behaviour the bundle configuration encodes |
| change config syntax or helper semantics | `examples/finch.example.js`, then README.md § Configuration | the user-facing contract, which is what breaks when the engine changes |
| touch the bundle, URL schemes, or default-browser candidacy | `Info.plist` | which schemes Finch claims — `http`, `https` and `mailto`, deliberately not the `public.html` document type, for the reason README.md § Install gives — and `LSUIElement` for the no-Dock-icon behaviour |
| change how it is built, run, or measured | `Makefile` | `build`, `run`, `test URL=…`, `loc`, and how the `.app` is assembled and ad-hoc signed |

## Source map

| File | Responsibility |
|---|---|
| `Sources/Finch/main.swift` | Entry point; sets the activation policy that keeps Finch out of the Dock |
| `Sources/Finch/AppDelegate.swift` | Apple Event (`GURL`) handling, opening the chosen browser, the menu bar, `--test` and `--bench` |
| `Sources/Finch/Engine.swift` | The hot path: config compiled to native matchers, rewrite pipeline, first-match-wins resolution |
| `Sources/Finch/Loader.swift` | Reads `~/.finch.js` and evaluates it in a JavaScriptCore context |
| `Sources/Finch/Helpers.swift` | `JS_PRELUDE` — JavaScript injected into every config context: a `URL` polyfill (JavaScriptCore has no DOM, so `URL` does not otherwise exist) and the marker-object helpers `domain`, `from`, `strip` and `running`, which return data rather than functions so `Engine.swift` can compile them to native Swift at load time. `docs/architecture.md` explains why |
| `Sources/Finch/Recents.swift` | In-memory list of the last few routes shown in the menu bar |

## Not in this repository

These are load-bearing and cannot be discovered by reading the repo.

| What | Where | Why it matters |
|---|---|---|
| The Homebrew tap holding the cask that installs Finch | `~/repos/github/homebrew-finch` on this machine; `expelledboy/homebrew-finch` on GitHub | A release is not finished in this repo. The cask's `version` and `sha256` must be bumped there too — see `docs/homebrew.md` |
| The user's live routing rules | `~/.finch.js` | Not version-controlled and not an example. `make test URL=…` and the running app both read it |
| The installed application | `/Applications/Finch.app` | Where the cask installs. A local `make run` registers the *repo's* copy instead, which then wins the bundle id |
| Released versions | git tags (`v0.1.0`, `v0.1.1`); no GitHub Release objects | The cask fetches GitHub's auto-generated tag tarball, so a tag alone is a release |
| Conversation with the author of Finicky, the established macOS browser router Finch is positioned against | `github.com/johnste/finicky/discussions/523` | Context for positioning claims |

## Gotchas with no other home

- **Two copies of the app fight over the bundle id.** LaunchServices resolves
  `com.finch.browser` to whichever bundle was registered last, so after
  `make run` the repo's `Finch.app` handles URLs instead of the installed one.
  Undo with `lsregister -u <repo>/Finch.app` then `lsregister -f
  /Applications/Finch.app`. The binary is at
  `/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister`.
- **The opener must come from the Apple Event's sender pid.**
  `NSWorkspace.frontmostApplication` reports Finch itself, because handling the
  event makes Finch frontmost — so `from()` rules, which match on the bundle id
  of the app the link came from, silently never match. See `openerBundleId` in
  `AppDelegate.swift`.
- **A stale file-type or URL-scheme binding survives `lsregister -kill -r`.**
  The rebuilt database is correct but `lsd`, the Launch Services daemon, keeps
  serving an in-memory copy of the old handler map; kill `lsd` too. Fuller note
  in `docs/architecture.md` § Platform behaviour.
- **The menu bar icon can be placed off-screen.** macOS persists its slot in
  `NSStatusItem Preferred Position Item-0` under the `com.finch.browser`
  defaults domain; a position saved on a wider display can leave it invisible.
  Quit Finch, `defaults delete` that key, relaunch. Reading the position through
  Accessibility is not a reliable check — it has reported an off-screen
  coordinate for an icon that was plainly visible.

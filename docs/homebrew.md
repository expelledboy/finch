# Homebrew distribution

How Finch ships to users via Homebrew, and how to maintain it.

## The two-repo setup

| Repo | Purpose |
|---|---|
| [`expelledboy/finch`](https://github.com/expelledboy/finch) | Source code. Tagged releases. |
| [`expelledboy/homebrew-finch`](https://github.com/expelledboy/homebrew-finch) | Homebrew tap. Contains the Cask file pointing at tagged releases. |

User installs with one command:

```sh
brew install --cask expelledboy/finch/finch
```

`brew tap expelledboy/finch` is implied by the third path component. After install, brew clones the tap into `/opt/homebrew/Library/Taps/expelledboy/homebrew-finch/`, reads `Casks/finch.rb`, and runs the install steps.

## Why a Cask, not a Formula

Finch is a `.app` bundle that needs to land in `/Applications` so Launch Services discovers it as a default-browser candidate. Formulae symlink binaries into `/opt/homebrew/bin/` — that path is invisible to Launch Services for `.app` registration. Casks have the `app` stanza specifically for placing bundles in `/Applications`.

## Why build-from-source, not binary distribution

Three options exist for distributing a macOS app via Homebrew:

| Approach | Works for unsigned apps? | UX |
|---|---|---|
| Signed + notarized binary | Yes | One-click install |
| Unsigned binary download | **No** | Gatekeeper blocks; user must `xattr -dr com.apple.quarantine` |
| Build from source on user's machine | **Yes** | One-click install |

The trick: the `com.apple.quarantine` xattr is only attached to files that were *downloaded* by quarantine-aware clients (browsers, brew's downloader). Files produced locally by `swift build` carry no quarantine attribute, so Gatekeeper allows them to run without prompting.

This sidesteps the cost of an Apple Developer Program membership ($99/year for Developer ID + notarization). When Finch eventually has signed builds, the cask switches to the binary-distribution form — same tap, just a new cask version.

## How the cask works

[`homebrew-finch/Casks/finch.rb`](https://github.com/expelledboy/homebrew-finch/blob/main/Casks/finch.rb):

```ruby
cask "finch" do
  version "0.1.0"
  sha256 "4c972fc1774c8a1b278744475ac2f74f08db0b03511147e2265c5a32c28cda57"
  url "https://github.com/expelledboy/finch/archive/refs/tags/v#{version}.tar.gz"
  ...
  depends_on macos: ">= :ventura"

  preflight do
    src = "#{staged_path}/finch-#{version}"
    # ...sanity check for swift toolchain...
    system_command "/usr/bin/make", args: ["build"], chdir: src, must_succeed: true
  end

  app "finch-#{version}/Finch.app", target: "Finch.app"

  postflight do
    # Force Launch Services to index the new bundle immediately
    system_command ".../lsregister", args: ["-f", "#{appdir}/Finch.app"]
  end
end
```

What happens on `brew install --cask`:

1. **Download.** Brew fetches `v0.1.0.tar.gz` from GitHub Releases, verifies SHA256.
2. **Stage.** Tarball extracts to a temporary `staged_path`. Because GitHub release tarballs are wrapped in a directory named after the tag, the actual source lives at `staged_path/finch-0.1.0/`.
3. **Preflight.** We `cd` into `finch-0.1.0/` and run `make build`, which runs `swift build -c release` and assembles `Finch.app` in place.
4. **App stanza.** Brew moves `finch-0.1.0/Finch.app` into `/Applications/Finch.app`.
5. **Postflight.** We invoke `lsregister -f /Applications/Finch.app` so Launch Services indexes it immediately, instead of waiting for a re-login.

The user then needs to manually:
- Launch Finch (menu bar 🐦 appears)
- Create `~/.finch.js`
- System Settings → Default web browser → Finch

We could *partially* automate the last step by calling `LSSetDefaultHandlerForURLScheme("http", "com.finch.browser")` on first launch, which triggers macOS's native confirmation prompt. Not done yet — see [FEATURES.md](../FEATURES.md).

## Release workflow

When shipping a new version of Finch:

```sh
# 1. In the finch repo: bump the bundle version, THEN tag.
# The cask builds from the tag's tarball, so a version bumped after tagging
# ships an app whose About/Info.plist disagrees with the release. This step is
# how v0.1.0 and v0.1.1 both shipped Info.plist 0.1.0.
cd ~/repos/github/finch
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 0.2.0" Info.plist
git commit -am "v0.2.0: what's new"
git tag v0.2.0 -m "v0.2.0 — what's new"
git push origin main v0.2.0

# 2. Compute the new tarball SHA
curl -sL https://github.com/expelledboy/finch/archive/refs/tags/v0.2.0.tar.gz \
  -o /tmp/finch.tar.gz
shasum -a 256 /tmp/finch.tar.gz

# 3. In the tap repo: bump version + sha256
cd ~/repos/github/homebrew-finch
$EDITOR Casks/finch.rb        # update `version` and `sha256` lines
git add Casks/finch.rb
git commit -m "Bump finch to 0.2.0"
git push

# 4. Verify locally
brew update
brew style --cask expelledboy/finch/finch
brew upgrade --cask finch     # actual install test
```

Users update with:

```sh
brew update && brew upgrade --cask finch
```

## Known audit caveats

`brew audit --cask --new --strict` currently reports two issues that are spurious or irrelevant:

1. **"GitHub repository not notable enough (<30 forks, <30 watchers and <75 stars)"**
   Only matters for submission to `homebrew/cask`. Personal taps are exempt.

2. **"No binaries in App: ..."** + `exception while auditing finch: index 0 outside of array bounds: 0...0`
   The audit appears to inspect the `.app` before preflight has run, finds no executables in an empty bundle, and crashes its own array indexing. The actual `brew install --cask` works correctly because preflight runs in the right order during install.

Real `brew install --cask` succeeds despite these audit warnings.

## When to switch to signed binary distribution

Trigger conditions for moving away from build-from-source:

- Apple Developer ID acquired ($99/year)
- Build pipeline producing notarized `Finch.app.zip` artifacts attached to GitHub Releases
- Significant fraction of users without Xcode CLT (currently this is unknown — anyone reading the README likely has it)

The migration is small: drop the `preflight` build step, change `url` to point at the release zip, add `sha256` for the zip, drop `app "finch-#{version}/Finch.app"` back to plain `app "Finch.app"`. Same tap, new cask version.

## Why not submit to homebrew/cask?

The official `homebrew/cask` repository [no longer accepts unsigned or unnotarized apps](https://docs.brew.sh/Acceptable-Casks#stable-versions) (full enforcement Sept 2026). A personal tap is the correct venue until Finch has signing in place. Even after signing, there's no urgency to submit upstream — personal taps work fine forever and let us iterate without review latency.

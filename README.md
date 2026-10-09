# Chrome Tab Router

A tiny macOS app that you set as the default browser. When you click a link, it focuses an already-open Chrome tab with the same URL instead of opening a duplicate. If no tab matches, it opens the link in a new tab.

I use it for links in terminal output (OSC 8 hyperlinks), such as PR URLs, so that clicking the same PR twice does not pile up tabs.

## How it works

- A link click arrives at the app, which asks Chrome for every tab URL through Apple Events.
- URLs are compared after dropping the query string and fragment. GitHub pull request URLs are also compared by PR number, so `/pull/12/files` and `/pull/12` are the same tab.
- On a match, the tab is selected and Chrome is brought to the front. Without one, Chrome opens the URL in a new tab.
- A Chrome started with `--user-data-dir` or `--remote-debugging` is ignored, so automation browsers are not touched.
- While a Meet picture-in-picture window is open, Chrome ignores "move this window to the front". The app detects that case, logs `focus-behind-pip`, and activates Chrome through an Apple Event instead.

## Requirements

- macOS and Google Chrome
- Swift toolchain (`swiftc`, from Xcode or the Command Line Tools)

## Install

```sh
./build.sh                 # builds ~/Applications/Chrome Tab Router.app
./install-launchagent.sh   # optional: keep it running from login
```

Then open System Settings > Desktop & Dock > Default web browser and choose Chrome Tab Router.

`build.sh` signs with an Apple Development certificate when one is available (override with `SIGN_IDENTITY`). Ad-hoc signing changes the signature on every build, which makes macOS ask again for permission to control Chrome.

The first link click asks for permission to control Google Chrome. Allow it.

## Configuration

Optional file `~/.config/chrome-tab-router/config.json`:

```json
{ "profile": "Profile 1" }
```

`profile` is the Chrome profile directory name (not the display name) passed as `--profile-directory` when the app has to launch Chrome. Without it, Chrome uses its last used profile.

## Log

Every handled link appends one line to `/tmp/chrome-router-activation.txt`: the route taken (`focus`, `focus-behind-pip`, `no-matching-tab`, `no-window`, `chrome-not-running`), per-step timings, and the frontmost app before and after.

## Tests

```sh
./run-tests.sh
```

## License

MIT

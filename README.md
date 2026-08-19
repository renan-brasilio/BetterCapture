<p align="center">
  <img src="docs/assets/capster-icon.png" alt="Capster Logo" width="140">
</p>

<h1 align="center">Capster</h1>

<p align="center">
    The macOS screen recorder for the rest of us - always free and open source with a native look and feel 📺
</p>

<p align="center">
  <a href="#installation">Installation</a> ·
  <a href="#features">Features</a> ·
  <a href="#whats-new-in-capster">What's New</a> ·
  <a href="#contributing">Contributing</a>
</p>

> **Capster is a fork of [BetterCapture](https://github.com/jsattler/BetterCapture) by Joshua Sattler**, extended with recording pause/resume, cancellation, a pre-recording countdown, single-track mixed audio, and more. See [What's New in Capster](#whats-new-in-capster) below - the same attribution is also shown in the app's own Settings → About tab.

## Features

- **Native macOS integration**: Built with SwiftUI and ScreenCaptureKit, lives in your menu bar
- **Professional encoding**: ProRes 422/4444, HEVC (H.265), and H.264 codecs with support for alpha channel and HDR
- **Flexible audio capture**: Record system audio and microphone simultaneously, mixed into a single playable track
- **Content filtering**: Exclude specific content from recordings
- **Privacy-focused**: No tracking, no analytics, all recordings stored locally
- **MIT licensed**: Free and open source

## What's New in Capster

Changes on top of upstream BetterCapture:

- **Pause / Resume**: pause an in-progress recording and resume later - paused time is cleanly cut from the output instead of leaving a frozen-frame gap
- **Cancel Recording**: discard the current recording entirely (deletes the in-progress file) instead of only being able to stop-and-save
- **Pre-recording countdown**: optional 3-second "get ready" countdown overlay before capture starts, skippable with any key press or click
- **Presenter Overlay assist**: macOS gives apps no API to turn on Presenter Overlay automatically - Capster now pauses right after starting the share and prompts you to enable it manually from Control Center, then resumes once you confirm, instead of silently recording without it
- **Fixed silent/missing microphone audio**: system audio and microphone are now mixed into a single audio track (previously, writing them as two separate tracks meant most players only played the first one back, making the mic sound silent or missing); also fixed the mic silently failing when the previously-selected device was no longer available
- **Configurable output filename**: set your own filename template with `{date}`/`{time}` placeholders and a live preview, instead of a fixed naming scheme
- **Cleaner shutdown**: quitting (Quit button, ⌘Q, Dock, logout) now properly finishes or stops an in-progress recording first, instead of leaving the screen-sharing session stuck active in the background

## Installation

No prebuilt releases are published for this fork yet - build it from source:

```bash
git clone https://github.com/renan-brasilio/BetterCapture.git
cd BetterCapture
open BetterCapture.xcodeproj
```

Then select the `BetterCapture` scheme, choose your own signing team under **Signing & Capabilities**, and hit Run (⌘R).

**Requirements**: macOS 15.2 (Sequoia) or later

## Automation

Capster supports a custom URL scheme for external tools (Raycast, Shortcuts, Alfred):

| URL | Action |
|---|---|
| `capster://toggle` | Stop recording if active; otherwise open content selection (Pick Content or Select Area) before recording |
| `capster://toggle-copy` | Same as `toggle`, but copies the saved recording to the clipboard when stopping |
| `capster://open-recordings` | Open the output folder in Finder |

Example:

```bash
open "capster://toggle"
```

## Contributing

We welcome contributions of all kinds! Please see our [Contributing Guidelines](CONTRIBUTING.md) for more details on how to get involved.

## Acknowledgments

Special thanks to these projects for their excellent work and inspiration:

- [**BetterCapture**](https://github.com/jsattler/BetterCapture) by Joshua Sattler - the original project this is forked from
- [**QuickRecorder**](https://github.com/lihaoyun6/QuickRecorder)
- [**Azayaka**](https://github.com/Mnpn/Azayaka)
- [**Ghostty**](https://github.com/ghostty-org/ghostty)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

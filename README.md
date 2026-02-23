# <img src="znueni/Assets.xcassets/AppIcon.appiconset/icon_64x64.png" width="32" alt="znueni app icon"> znueni

A minimal macOS menu bar Pomodoro timer. Free, open source, and lightweight with zero dependencies in just a few hundred lines of Swift.

Named after _Znüni_ (sounds like "tsnoo-nee"), a Swiss German tradition of taking a small snack break around 9 AM — literally "at nine o'clock".

## Features

- **Menu bar native** - lives in your status bar with a progress arc, no dock icon, no windows
- **Focus + break cycles** - configurable durations (15-60 min focus, 3-15 min break)
- **Pause / resume** - pause and resume during focus or break
- **Long breaks** - automatic long break after N sessions (configurable)
- **Session tracking** - counts completed focus sessions, resets each launch
- **Full-screen break overlay** - covers all displays to enforce breaks, dismiss with Escape
- **Auto-start breaks** - optionally transitions straight from focus to break
- **System notifications** - alerts when sessions end, with sound cues

## Why znueni?

- **Zero dependencies** - built entirely on Apple frameworks (SwiftUI, AppKit, Foundation)
- **Lightweight** - tiny memory footprint, no background services, no Electron
- **Free & open source** - MIT licensed, no accounts, no telemetry, no ads

## Install

**Homebrew:**

```bash
brew install mwalterskirchen/tap/znueni
```

**Manual:** Download the latest `.dmg` from [Releases](https://github.com/mwalterskirchen/znueni/releases), open it, and drag znueni to Applications. On first launch, right-click → Open to bypass Gatekeeper.

## Architecture

a few hundred lines of Swift across 4 files. SwiftUI for the menu and overlay UI, AppKit for multi-monitor window management.

| File                           | Role                                                               |
| ------------------------------ | ------------------------------------------------------------------ |
| `znueniApp.swift`              | `MenuBarExtra` entry point, settings UI, progress arc rendering    |
| `TimerState.swift`             | `@Observable` state machine, timer logic, UserDefaults persistence |
| `BreakOverlayController.swift` | Full-screen `NSWindow` management across all displays              |
| `BreakOverlayView.swift`       | Break countdown overlay view                                       |

State flow: `idle → focus → focusEnded → breaking → breakEnded → idle`

## Build

Requires Xcode 16+ and macOS 15.6+.

```bash
xcodebuild -scheme znueni -configuration Release build
```

Or open `znueni.xcodeproj` in Xcode and press ⌘R.

## License

MIT

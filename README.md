# znueni

A minimal macOS menu bar Pomodoro timer. Named after the Swiss German tradition of *Znüni* — a mid-morning break to recharge.

## Features

- **Menu bar native** — lives in your status bar, no dock icon, no windows
- **Focus + break cycles** — configurable durations (15–60 min focus, 3–15 min break)
- **Full-screen break overlay** — covers all displays to enforce breaks, dismiss with Escape
- **Auto-start breaks** — optionally transitions straight from focus to break
- **System notifications** — alerts when sessions end, with sound cues

## Architecture

~350 lines of Swift across 4 files — SwiftUI for the menu and overlay UI, AppKit for multi-monitor window management.

| File | Role |
|------|------|
| `znueniApp.swift` | `MenuBarExtra` entry point, settings UI |
| `TimerState.swift` | `@Observable` state machine, timer logic, UserDefaults persistence |
| `BreakOverlayController.swift` | Full-screen `NSWindow` management across all displays |
| `BreakOverlayView.swift` | Break countdown overlay view |

State flow: `idle → focus → focusEnded → breaking → breakEnded → idle`

No external dependencies — only Foundation, SwiftUI, AppKit, and UserNotifications.

## Build

Requires Xcode 16+ and macOS 15.6+.

```bash
xcodebuild -scheme znueni -configuration Release build
```

Or open `znueni.xcodeproj` in Xcode and press ⌘R.

## License

MIT

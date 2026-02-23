# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

znueni — macOS menu bar Pomodoro timer. Swift/SwiftUI, no external dependencies. Bundle ID: `ch.mwalterskirchen.znueni`.

## Build

```bash
xcodebuild -scheme znueni -configuration Debug build
```

No tests exist. No linter configured.

## Architecture

Menu bar-only app (LSUIElement, no main window). 4 source files in `znueni/`:

- **znueniApp.swift** — `@main` entry, `MenuBarExtra` with `.menu` style, settings submenus
- **TimerState.swift** — `@Observable @MainActor` state machine, timer logic, UserDefaults persistence, notifications
- **BreakOverlayController.swift** — AppKit `NSWindow` manager, full-screen overlay on all displays
- **BreakOverlayView.swift** — SwiftUI view hosted in overlay via `NSHostingView`

State flow: `idle → focus → focusEnded → breaking → breakEnded → idle`

## Patterns

- Settings (focusDuration, breakDuration, autoStartBreak) use UserDefaults with Observable `access()`/`withMutation()` wrappers
- DEBUG builds include 1-min durations for testing; RELEASE starts at 15 min
- `formatTime()` is a top-level function in TimerState.swift (shared by overlay view)
- `Int.clamped(min:fallback:)` private extension for safe UserDefaults reads
- Hybrid SwiftUI/AppKit: SwiftUI for menu + overlay view, AppKit for window management + sound + event monitoring

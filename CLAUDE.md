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

Menu bar-only app (LSUIElement, no main window). 5 source files in `znueni/`:

- **znueniApp.swift** — `@main` entry, `MenuBarExtra` with `.menu` style, `Window` scene for settings, CoreGraphics progress arc rendering
- **TimerState.swift** — `@Observable @MainActor` state machine, timer logic, UserDefaults persistence, notifications, pause/resume, session tracking
- **SettingsView.swift** — standalone settings window (durations, behavior, about/version), dock icon management via activation policy
- **BreakOverlayController.swift** — AppKit `NSWindow` manager, full-screen overlay on all displays
- **BreakOverlayView.swift** — SwiftUI view hosted in overlay via `NSHostingView`, long break variant

State flow: `idle → focus → focusEnded → breaking → breakEnded → idle` (focus/breaking support pause/resume)

## Features

- Pause/resume during focus and break phases
- Session counter (UserDefaults-persisted) with reset
- Long break after N sessions (configurable duration + interval)
- Progress arc + time text in menu bar (CoreGraphics template NSImage)

## Patterns

- Settings (focusDuration, breakDuration, longBreakDuration, sessionsUntilLongBreak, autoStartNext) use UserDefaults with Observable `access()`/`withMutation()` wrappers
- DEBUG builds include 1-min durations for testing; RELEASE starts at 15 min
- `formatTime()` is a top-level function in TimerState.swift (shared by overlay view)
- `Int.clamped(min:fallback:)` private extension for safe UserDefaults reads
- Hybrid SwiftUI/AppKit: SwiftUI for menu + overlay view, AppKit for window management + sound
- Menu bar label: `Image("croissant")` when idle, `makeMenuBarImage()` NSImage with arc + text when active

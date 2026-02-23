import SwiftUI

@main
struct znueniApp: App {
    @State private var timer = TimerState()

    var body: some Scene {
        MenuBarExtra {
            if timer.phase != .idle {
                Text(timer.statusText)
                    .disabled(true)
                Divider()
            }

            switch timer.phase {
            case .idle:
                Button("Start Focus") { timer.startFocus() }
            case .focus:
                Button("Stop Focus") { timer.stopFocus() }
            case .focusEnded:
                Button("Start Break") { timer.startBreak() }
                Button("Skip") { timer.skipBreak() }
            case .breaking:
                Button("End Break") { timer.endBreak() }
            case .breakEnded:
                Button("Start Focus") { timer.startFocus() }
            }

            Divider()

            Menu("Settings") {
                Menu("Focus: \(timer.focusDuration) min") {
                    ForEach(TimerState.focusOptions, id: \.self) { mins in
                        Toggle("\(mins) min", isOn: Binding(
                            get: { timer.focusDuration == mins },
                            set: { if $0 { timer.focusDuration = mins } }
                        ))
                    }
                }
                Menu("Break: \(timer.breakDuration) min") {
                    ForEach(TimerState.breakOptions, id: \.self) { mins in
                        Toggle("\(mins) min", isOn: Binding(
                            get: { timer.breakDuration == mins },
                            set: { if $0 { timer.breakDuration = mins } }
                        ))
                    }
                }
                Toggle("Auto-start break", isOn: Bindable(timer).autoStartBreak)
            }

            Divider()

            Button("Quit znueni") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            if timer.phase == .idle {
                Image("croissant")
            } else {
                Text(timer.menuBarTitle)
            }
        }
        .menuBarExtraStyle(.menu)
    }

    init() {
        TimerState.requestNotificationPermission()
    }
}

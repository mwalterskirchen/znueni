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
                    ForEach([1, 15, 25, 30, 45, 60], id: \.self) { mins in
                        Button("\(mins) min") { timer.focusDuration = mins }
                    }
                }
                Menu("Break: \(timer.breakDuration) min") {
                    ForEach([1, 3, 5, 10, 15], id: \.self) { mins in
                        Button("\(mins) min") { timer.breakDuration = mins }
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

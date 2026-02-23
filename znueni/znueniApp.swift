import SwiftUI
import AppKit
import ServiceManagement

@main
struct znueniApp: App {
    @State private var timer = TimerState()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(timer: timer)
        } label: {
            MenuBarLabel(timer: timer)
        }
        .menuBarExtraStyle(.menu)
    }

    init() {
        TimerState.requestNotificationPermission()
    }
}

private struct MenuBarLabel: View {
    let timer: TimerState

    var body: some View {
        if timer.phase == .idle {
            Image("croissant")
        } else {
            Image(nsImage: makeMenuBarImage(
                progress: timer.progress,
                text: timer.menuBarTitle,
                isPaused: timer.isPaused
            ))
        }
    }

    private func makeMenuBarImage(progress: Double, text: String, isPaused: Bool) -> NSImage {
        let fontSize: CGFloat = 12
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (text as NSString).size(withAttributes: attrs)

        let arcDiameter: CGFloat = 16
        let spacing: CGFloat = 4
        let height: CGFloat = 18

        let pauseIcon = isPaused
            ? NSImage(systemSymbolName: "pause.fill", accessibilityDescription: "Paused")?
                .withSymbolConfiguration(.init(pointSize: fontSize, weight: .medium))
            : nil
        let leadingWidth = pauseIcon?.size.width ?? arcDiameter

        let width = leadingWidth + spacing + textSize.width + 2

        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            if let pauseIcon {
                let iconY = (height - pauseIcon.size.height) / 2
                pauseIcon.draw(in: CGRect(x: 0, y: iconY, width: pauseIcon.size.width, height: pauseIcon.size.height))
            } else {
                let arcCenter = CGPoint(x: arcDiameter / 2, y: rect.midY)
                let radius = arcDiameter / 2 - 1.5
                let startAngle: CGFloat = 90
                let endAngle = 90 - CGFloat(progress) * 360

                let track = NSBezierPath()
                track.appendArc(withCenter: arcCenter, radius: radius, startAngle: 0, endAngle: 360)
                NSColor.labelColor.withAlphaComponent(0.2).setStroke()
                track.lineWidth = 2
                track.stroke()

                if progress > 0 {
                    let arc = NSBezierPath()
                    arc.appendArc(withCenter: arcCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                    NSColor.labelColor.setStroke()
                    arc.lineWidth = 2
                    arc.lineCapStyle = .round
                    arc.stroke()
                }
            }

            let textOrigin = CGPoint(x: leadingWidth + spacing, y: (height - textSize.height) / 2)
            (text as NSString).draw(at: textOrigin, withAttributes: [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ])

            return true
        }

        image.isTemplate = true
        return image
    }
}

private struct MenuContent: View {
    let timer: TimerState
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        switch timer.phase {
        case .idle:
            Button("Start Focus") { timer.startFocus() }
        case .focus:
            if timer.isPaused {
                Button("Resume") { timer.resume() }
            } else {
                Button("Pause") { timer.pause() }
            }
            Button("Skip") { timer.skipFocus() }
            Button("Stop Focus") { timer.stopFocus() }
        case .focusEnded:
            if timer.isLongBreak {
                Button("Start Long Break") { timer.startBreak() }
            } else {
                Button("Start Break") { timer.startBreak() }
            }
            Button("Skip") { timer.skipBreak() }
        case .breaking:
            if timer.isPaused {
                Button("Resume") { timer.resume() }
            } else {
                Button("Pause") { timer.pause() }
            }
            Button("Skip") { timer.endBreak() }
        case .breakEnded:
            Button("Start Focus") { timer.startFocus() }
        }

        if timer.completedSessions > 0 {
            Divider()
            Text("Sessions: \(timer.completedSessions)")
                .disabled(true)
            Button("Reset Sessions") { timer.resetSessions() }
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
            Menu("Long Break: \(timer.longBreakDuration) min") {
                ForEach(TimerState.longBreakOptions, id: \.self) { mins in
                    Toggle("\(mins) min", isOn: Binding(
                        get: { timer.longBreakDuration == mins },
                        set: { if $0 { timer.longBreakDuration = mins } }
                    ))
                }
            }
            Menu("Long Break Every: \(timer.sessionsUntilLongBreak)") {
                ForEach(TimerState.sessionsUntilLongBreakOptions, id: \.self) { n in
                    Toggle("\(n) sessions", isOn: Binding(
                        get: { timer.sessionsUntilLongBreak == n },
                        set: { if $0 { timer.sessionsUntilLongBreak = n } }
                    ))
                }
            }
            Toggle("Auto-start next session", isOn: Bindable(timer).autoStartNext)
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }
            ))
        }

        Divider()

        Button("Quit znueni") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

import SwiftUI
import AppKit

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

        Window("Settings", id: "settings") {
            SettingsView(timer: timer)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .restorationBehavior(.disabled)
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
                isPaused: timer.isPaused,
                phase: timer.phase
            ))
        }
    }

    private func makeMenuBarImage(progress: Double, text: String, isPaused: Bool, phase: TimerPhase) -> NSImage {
        let fontSize: CGFloat = 12
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (text as NSString).size(withAttributes: attrs)

        let arcDiameter: CGFloat = 16
        let spacing: CGFloat = 4
        let height: CGFloat = 18

        let leadingIcon: NSImage? = if isPaused {
            NSImage(systemSymbolName: "pause.fill", accessibilityDescription: "Paused")?
                .withSymbolConfiguration(.init(pointSize: fontSize, weight: .medium))
        } else if phase == .breaking {
            NSImage(systemSymbolName: "cup.and.heat.waves", accessibilityDescription: "Break")?
                .withSymbolConfiguration(.init(pointSize: fontSize, weight: .medium))
        } else {
            nil
        }
        let leadingWidth = leadingIcon?.size.width ?? arcDiameter

        let width = leadingWidth + spacing + textSize.width + 2

        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            if let leadingIcon {
                let iconY = (height - leadingIcon.size.height) / 2
                leadingIcon.draw(in: CGRect(x: 0, y: iconY, width: leadingIcon.size.width, height: leadingIcon.size.height))
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

private struct SettingsButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        } label: { Label("Settings…", systemImage: "gear") }
        .keyboardShortcut(",")
    }
}

private struct MenuContent: View {
    let timer: TimerState

    private var stateLabel: String {
        switch timer.phase {
        case .idle: "Idle"
        case .focus: timer.isPaused ? "Focus · Paused" : "Focus"
        case .focusEnded: "Focus"
        case .breaking: timer.isPaused ? "Break · Paused" : "Break"
        case .breakEnded: "Break"
        }
    }

    var body: some View {
        Text(stateLabel).disabled(true)
        Divider()
        switch timer.phase {
        case .idle:
            Button { timer.startFocus() } label: { Label("Start Focus", systemImage: "play.fill") }
        case .focus:
            if timer.isPaused {
                Button { timer.resume() } label: { Label("Resume", systemImage: "play.fill") }
            } else {
                Button { timer.pause() } label: { Label("Pause", systemImage: "pause.fill") }
            }
            Button { timer.skipFocus() } label: { Label("Skip", systemImage: "forward.end.fill") }
            Button { timer.stopFocus() } label: { Label("Stop Focus", systemImage: "stop.fill") }
        case .focusEnded:
            if timer.isLongBreak {
                Button { timer.startBreak() } label: { Label("Start Long Break", systemImage: "cup.and.heat.waves.fill") }
            } else {
                Button { timer.startBreak() } label: { Label("Start Break", systemImage: "cup.and.heat.waves.fill") }
            }
            Button { timer.skipBreak() } label: { Label("Skip", systemImage: "forward.end.fill") }
        case .breaking:
            if timer.isPaused {
                Button { timer.resume() } label: { Label("Resume", systemImage: "play.fill") }
            } else {
                Button { timer.pause() } label: { Label("Pause", systemImage: "pause.fill") }
            }
            Button { timer.skipBreak() } label: { Label("Skip", systemImage: "forward.end.fill") }
        case .breakEnded:
            Button { timer.startFocus() } label: { Label("Start Focus", systemImage: "play.fill") }
        }

        if timer.completedSessions > 0 {
            Divider()
            Label("Sessions: \(timer.completedSessions)", systemImage: "checkmark.circle")
        }

        Divider()

        SettingsButton()

        Divider()

        Button { NSApplication.shared.terminate(nil) } label: { Label("Quit znueni", systemImage: "xmark.circle") }
            .keyboardShortcut("q")
    }
}

import Foundation
import AppKit
import UserNotifications

enum TimerPhase {
    case idle, focus, focusEnded, breaking, breakEnded
}

@Observable
@MainActor
class TimerState {
    var phase: TimerPhase = .idle
    var remainingSeconds: Int = 0

    var focusDuration: Int {
        get {
            access(keyPath: \.focusDuration)
            return UserDefaults.standard.integer(forKey: "focusDuration").clamped(min: 1, fallback: 25)
        }
        set {
            withMutation(keyPath: \.focusDuration) {
                UserDefaults.standard.set(newValue, forKey: "focusDuration")
            }
        }
    }

    var breakDuration: Int {
        get {
            access(keyPath: \.breakDuration)
            return UserDefaults.standard.integer(forKey: "breakDuration").clamped(min: 1, fallback: 5)
        }
        set {
            withMutation(keyPath: \.breakDuration) {
                UserDefaults.standard.set(newValue, forKey: "breakDuration")
            }
        }
    }

    var autoStartBreak: Bool {
        get {
            access(keyPath: \.autoStartBreak)
            return UserDefaults.standard.object(forKey: "autoStartBreak") as? Bool ?? true
        }
        set {
            withMutation(keyPath: \.autoStartBreak) {
                UserDefaults.standard.set(newValue, forKey: "autoStartBreak")
            }
        }
    }

    var statusText: String {
        switch phase {
        case .idle: "Ready"
        case .focus: "Focus — \(formatTime(remainingSeconds))"
        case .focusEnded: "Focus complete!"
        case .breaking: "Break — \(formatTime(remainingSeconds))"
        case .breakEnded: "Break over!"
        }
    }

    var menuBarTitle: String {
        switch phase {
        case .idle: "znueni"
        case .focus, .breaking: formatTime(remainingSeconds)
        case .focusEnded: "Break?"
        case .breakEnded: "Done!"
        }
    }

    private var timer: Timer?
    private(set) var overlayController = BreakOverlayController()

    func startFocus() {
        remainingSeconds = focusDuration * 60
        phase = .focus
        startTicking()
    }

    func stopFocus() {
        stopTicking()
        phase = .idle
    }

    func startBreak() {
        remainingSeconds = breakDuration * 60
        phase = .breaking
        overlayController.show(timer: self)
        startTicking()
    }

    func skipBreak() {
        phase = .idle
    }

    func endBreak() {
        stopTicking()
        overlayController.dismiss()
        phase = .idle
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            stopTicking()
            switch phase {
            case .focus:
                NSSound(named: "Glass")?.play()
                sendNotification(title: "Focus ended", body: "Time for a break!")
                if autoStartBreak {
                    startBreak()
                } else {
                    phase = .focusEnded
                }
            case .breaking:
                phase = .breakEnded
                NSSound(named: "Purr")?.play()
                overlayController.dismiss()
                sendNotification(title: "Break ended", body: "Ready to focus again?")
            default:
                break
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

private extension Int {
    func clamped(min: Int, fallback: Int) -> Int {
        self >= min ? self : fallback
    }
}

import Foundation
import AppKit
import UserNotifications

enum TimerPhase {
    case idle, focus, focusEnded, breaking, breakEnded
}

func formatTime(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%d:%02d", m, s)
}

@Observable
@MainActor
class TimerState {
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    #if DEBUG
    static let focusOptions = [1, 15, 25, 30, 45, 60]
    static let breakOptions = [1, 3, 5, 10, 15]
    static let longBreakOptions = [1, 10, 15, 20, 30]
    #else
    static let focusOptions = [15, 25, 30, 45, 60]
    static let breakOptions = [3, 5, 10, 15]
    static let longBreakOptions = [10, 15, 20, 30]
    #endif
    static let sessionsUntilLongBreakOptions = [2, 3, 4, 5, 6]

    private enum Keys {
        static let focusDuration = "focusDuration"
        static let breakDuration = "breakDuration"
        static let autoStartNext = "autoStartNext"
        static let longBreakDuration = "longBreakDuration"
        static let sessionsUntilLongBreak = "sessionsUntilLongBreak"
    }

    var phase: TimerPhase = .idle
    var remainingSeconds: Int = 0
    var isPaused: Bool = false
    private(set) var totalSeconds: Int = 0

    var focusDuration: Int {
        get {
            access(keyPath: \.focusDuration)
            return defaults.integer(forKey: Keys.focusDuration).clamped(min: 1, fallback: 25)
        }
        set {
            withMutation(keyPath: \.focusDuration) {
                defaults.set(newValue, forKey: Keys.focusDuration)
            }
        }
    }

    var breakDuration: Int {
        get {
            access(keyPath: \.breakDuration)
            return defaults.integer(forKey: Keys.breakDuration).clamped(min: 1, fallback: 5)
        }
        set {
            withMutation(keyPath: \.breakDuration) {
                defaults.set(newValue, forKey: Keys.breakDuration)
            }
        }
    }

    var autoStartNext: Bool {
        get {
            access(keyPath: \.autoStartNext)
            return defaults.object(forKey: Keys.autoStartNext) as? Bool ?? true
        }
        set {
            withMutation(keyPath: \.autoStartNext) {
                defaults.set(newValue, forKey: Keys.autoStartNext)
            }
        }
    }

    var completedSessions: Int = 0

    var longBreakDuration: Int {
        get {
            access(keyPath: \.longBreakDuration)
            return defaults.integer(forKey: Keys.longBreakDuration).clamped(min: 1, fallback: 15)
        }
        set {
            withMutation(keyPath: \.longBreakDuration) {
                defaults.set(newValue, forKey: Keys.longBreakDuration)
            }
        }
    }

    var sessionsUntilLongBreak: Int {
        get {
            access(keyPath: \.sessionsUntilLongBreak)
            return defaults.integer(forKey: Keys.sessionsUntilLongBreak).clamped(min: 2, fallback: 4)
        }
        set {
            withMutation(keyPath: \.sessionsUntilLongBreak) {
                defaults.set(newValue, forKey: Keys.sessionsUntilLongBreak)
            }
        }
    }

    var isLongBreak: Bool {
        completedSessions > 0 && completedSessions % sessionsUntilLongBreak == 0
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }

    var statusText: String {
        let paused = isPaused ? " (Paused)" : ""
        switch phase {
        case .idle: return "Ready"
        case .focus: return "Focus — \(formatTime(remainingSeconds))\(paused)"
        case .focusEnded: return "Focus complete!"
        case .breaking: return "Break — \(formatTime(remainingSeconds))\(paused)"
        case .breakEnded: return "Break over!"
        }
    }

    var menuBarTitle: String {
        switch phase {
        case .idle: return "znueni"
        case .focus, .breaking: return formatTime(remainingSeconds)
        case .focusEnded: return "Break?"
        case .breakEnded: return "Done!"
        }
    }

    private var timer: Timer?
    private(set) var overlayController = BreakOverlayController()

    func startFocus() {
        isPaused = false
        remainingSeconds = focusDuration * 60
        totalSeconds = remainingSeconds
        phase = .focus
        startTicking()
    }

    func skipFocus() {
        stopTicking()
        isPaused = false
        completedSessions += 1
        if autoStartNext {
            startBreak()
        } else {
            phase = .focusEnded
        }
    }

    func stopFocus() {
        stopTicking()
        isPaused = false
        phase = .idle
    }

    func startBreak() {
        isPaused = false
        let duration = isLongBreak ? longBreakDuration : breakDuration
        remainingSeconds = duration * 60
        totalSeconds = remainingSeconds
        phase = .breaking
        overlayController.show(timer: self)
        startTicking()
    }

    func skipBreak() {
        stopTicking()
        isPaused = false
        overlayController.dismiss()
        if autoStartNext {
            startFocus()
        } else {
            phase = .breakEnded
        }
    }

    func endBreak() {
        stopTicking()
        isPaused = false
        overlayController.dismiss()
        phase = .idle
    }

    func pause() {
        isPaused = true
        stopTicking()
    }

    func resume() {
        isPaused = false
        startTicking()
    }

    private func startTicking() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }

    func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            stopTicking()
            switch phase {
            case .focus:
                completedSessions += 1
                NSSound(named: "Glass")?.play()
                sendNotification(title: "Focus ended", body: "Time for a break!")
                if autoStartNext {
                    startBreak()
                } else {
                    phase = .focusEnded
                }
            case .breaking:
                NSSound(named: "Purr")?.play()
                overlayController.dismiss()
                sendNotification(title: "Break ended", body: "Ready to focus again?")
                if autoStartNext {
                    startFocus()
                } else {
                    phase = .breakEnded
                }
            default:
                break
            }
        }
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

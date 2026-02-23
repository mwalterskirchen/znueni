import SwiftUI

struct BreakOverlayView: View {
    var timer: TimerState
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
            VStack(spacing: 24) {
                Text(timer.isLongBreak ? "Take a long break" : "Take a break")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                Text(formatTime(timer.remainingSeconds))
                    .font(.system(size: 72, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                if timer.isPaused {
                    Text("Paused")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .font(.title2)
            }
        }
        .ignoresSafeArea()
    }
}

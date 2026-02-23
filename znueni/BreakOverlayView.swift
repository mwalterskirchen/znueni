import SwiftUI

struct BreakOverlayView: View {
    var timer: TimerState
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
            VStack(spacing: 24) {
                Text("Take a break")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                Text(formatTime(timer.remainingSeconds))
                    .font(.system(size: 72, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
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

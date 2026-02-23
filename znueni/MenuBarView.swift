import SwiftUI

struct MenuBarView: View {
    @Bindable var timer: TimerState
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            phaseContent
            Divider()
            settingsSection
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 220)
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch timer.phase {
        case .idle:
            Button("Start Focus") { timer.startFocus() }
        case .focus:
            HStack {
                Text(formatTime(timer.remainingSeconds))
                    .font(.system(.title2, design: .monospaced))
                Spacer()
                Button("Stop") { timer.stopFocus() }
            }
        case .focusEnded:
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus complete!").font(.headline)
                HStack {
                    Button("Start Break") { timer.startBreak() }
                    Button("Skip") { timer.skipBreak() }
                }
            }
        case .breaking:
            HStack {
                Text(formatTime(timer.remainingSeconds))
                    .font(.system(.title2, design: .monospaced))
                Spacer()
                Button("End Break") { timer.endBreak() }
            }
        case .breakEnded:
            VStack(alignment: .leading, spacing: 8) {
                Text("Break over!").font(.headline)
                Button("Start Focus") { timer.startFocus() }
            }
        }
    }

    @ViewBuilder
    private var settingsSection: some View {
        DisclosureGroup("Settings", isExpanded: $showSettings) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Focus")
                    Spacer()
                    TextField("", value: $timer.focusDuration, format: .number)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("min")
                }
                HStack {
                    Text("Break")
                    Spacer()
                    TextField("", value: $timer.breakDuration, format: .number)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("min")
                }
            }
            .padding(.top, 4)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

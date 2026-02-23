import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var timer: TimerState
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Durations") {
                Picker("Focus", selection: $timer.focusDuration) {
                    ForEach(TimerState.focusOptions, id: \.self) { mins in
                        Text("\(mins) min").tag(mins)
                    }
                }
                Picker("Break", selection: $timer.breakDuration) {
                    ForEach(TimerState.breakOptions, id: \.self) { mins in
                        Text("\(mins) min").tag(mins)
                    }
                }
                Picker("Long Break", selection: $timer.longBreakDuration) {
                    ForEach(TimerState.longBreakOptions, id: \.self) { mins in
                        Text("\(mins) min").tag(mins)
                    }
                }
                Picker("Long Break Every", selection: $timer.sessionsUntilLongBreak) {
                    ForEach(TimerState.sessionsUntilLongBreakOptions, id: \.self) { n in
                        Text("\(n) sessions").tag(n)
                    }
                }
            }

            Section("Behavior") {
                Toggle("Auto-start next session", isOn: $timer.autoStartNext)
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                ))
            }

            Section("About") {
                LabeledContent("Version", value: versionString)
                Link("Check for Updates",
                     destination: URL(string: "https://github.com/mwalterskirchen/znueni/releases")!)
            }
        }
        .formStyle(.grouped)
        .frame(width: 320)
        .fixedSize()
        .onAppear {
            NSApp.setActivationPolicy(.regular)
        }
        .onDisappear {
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    private var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}

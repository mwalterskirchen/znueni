import SwiftUI

@main
struct znueniApp: App {
    @State private var timer = TimerState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timer: timer)
        } label: {
            Text(timer.menuBarTitle)
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        TimerState.requestNotificationPermission()
    }
}

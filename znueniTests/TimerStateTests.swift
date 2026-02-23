import XCTest
@testable import znueni

final class TimerStateTests: XCTestCase {
    private let suiteName = "ch.mwalterskirchen.znueniTests"
    private var defaults: UserDefaults!
    private var sut: TimerState!

    override func setUp() {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        sut = TimerState(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        sut = nil
    }

    // MARK: - formatTime

    func testFormatTimeZero() {
        XCTAssertEqual(formatTime(0), "0:00")
    }

    func testFormatTimeSixtyOne() {
        XCTAssertEqual(formatTime(61), "1:01")
    }

    func testFormatTimeThirtySixHundred() {
        XCTAssertEqual(formatTime(3600), "60:00")
    }

    // MARK: - State transitions

    func testStartFocusSetsPhase() {
        sut.startFocus()
        XCTAssertEqual(sut.phase, .focus)
    }

    func testStopFocusSetsIdle() {
        sut.startFocus()
        sut.stopFocus()
        XCTAssertEqual(sut.phase, .idle)
    }

    func testStartBreakSetsBreaking() {
        sut.startBreak()
        XCTAssertEqual(sut.phase, .breaking)
    }

    func testEndBreakSetsIdle() {
        sut.startBreak()
        sut.endBreak()
        XCTAssertEqual(sut.phase, .idle)
    }

    func testSkipBreakSetsIdle() {
        sut.phase = .focusEnded
        sut.skipBreak()
        XCTAssertEqual(sut.phase, .idle)
    }

    // MARK: - Pause/resume

    func testPauseSetsIsPaused() {
        sut.startFocus()
        sut.pause()
        XCTAssertTrue(sut.isPaused)
    }

    func testResumeClearsIsPaused() {
        sut.startFocus()
        sut.pause()
        sut.resume()
        XCTAssertFalse(sut.isPaused)
    }

    func testStartFocusResetsPaused() {
        sut.isPaused = true
        sut.startFocus()
        XCTAssertFalse(sut.isPaused)
    }

    // MARK: - Tick

    func testTickDecrementsRemainingSeconds() {
        sut.startFocus()
        let before = sut.remainingSeconds
        sut.tick()
        XCTAssertEqual(sut.remainingSeconds, before - 1)
    }

    func testFocusCompleteIncrementsSessions() {
        sut.autoStartBreak = false
        sut.startFocus()
        sut.remainingSeconds = 1
        sut.tick()
        XCTAssertEqual(sut.completedSessions, 1)
        XCTAssertEqual(sut.phase, .focusEnded)
    }

    func testFocusCompleteAutoStartBreak() {
        sut.autoStartBreak = true
        sut.startFocus()
        sut.remainingSeconds = 1
        sut.tick()
        XCTAssertEqual(sut.completedSessions, 1)
        XCTAssertEqual(sut.phase, .breaking)
    }

    func testBreakCompleteTransitionsToBreakEnded() {
        sut.startBreak()
        sut.remainingSeconds = 1
        sut.tick()
        XCTAssertEqual(sut.phase, .breakEnded)
    }

    func testTickDoesNothingAtZero() {
        sut.remainingSeconds = 0
        sut.tick()
        XCTAssertEqual(sut.remainingSeconds, 0)
    }

    // MARK: - Session counter

    func testResetSessionsZeroes() {
        sut.completedSessions = 5
        sut.resetSessions()
        XCTAssertEqual(sut.completedSessions, 0)
    }

    func testSessionsPersistInDefaults() {
        sut.completedSessions = 3
        XCTAssertEqual(defaults.integer(forKey: "completedSessions"), 3)
    }

    // MARK: - Long break

    func testIsLongBreakAtMultiple() {
        sut.completedSessions = 4
        XCTAssertTrue(sut.isLongBreak)
    }

    func testIsLongBreakNotAtZero() {
        sut.completedSessions = 0
        XCTAssertFalse(sut.isLongBreak)
    }

    func testIsLongBreakFalseAtNonMultiple() {
        sut.completedSessions = 3
        XCTAssertFalse(sut.isLongBreak)
    }

    func testStartBreakUsesLongBreakDuration() {
        sut.completedSessions = 4 // isLongBreak = true
        sut.longBreakDuration = 20
        sut.startBreak()
        XCTAssertEqual(sut.remainingSeconds, 20 * 60)
    }

    func testStartBreakUsesRegularDuration() {
        sut.completedSessions = 1
        sut.breakDuration = 5
        sut.startBreak()
        XCTAssertEqual(sut.remainingSeconds, 5 * 60)
    }

    // MARK: - Computed properties

    func testProgressAtStart() {
        XCTAssertEqual(sut.progress, 0)
    }

    func testProgressMidway() {
        sut.startFocus()
        let total = sut.totalSeconds
        sut.remainingSeconds = total / 2
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.001)
    }

    func testStatusTextIdle() {
        XCTAssertEqual(sut.statusText, "Ready")
    }

    func testStatusTextFocus() {
        sut.startFocus()
        XCTAssertTrue(sut.statusText.hasPrefix("Focus — "))
    }

    func testStatusTextFocusPaused() {
        sut.startFocus()
        sut.pause()
        XCTAssertTrue(sut.statusText.hasSuffix("(Paused)"))
    }

    func testStatusTextFocusEnded() {
        sut.phase = .focusEnded
        XCTAssertEqual(sut.statusText, "Focus complete!")
    }

    func testStatusTextBreaking() {
        sut.startBreak()
        XCTAssertTrue(sut.statusText.hasPrefix("Break — "))
    }

    func testStatusTextBreakEnded() {
        sut.phase = .breakEnded
        XCTAssertEqual(sut.statusText, "Break over!")
    }

    func testMenuBarTitleIdle() {
        XCTAssertEqual(sut.menuBarTitle, "znueni")
    }

    func testMenuBarTitleFocus() {
        sut.startFocus()
        let title = sut.menuBarTitle
        XCTAssertFalse(title.hasPrefix("⏸"))
        XCTAssertTrue(title.contains(":"))
    }

    func testMenuBarTitlePaused() {
        sut.startFocus()
        sut.pause()
        XCTAssertTrue(sut.menuBarTitle.hasPrefix("⏸"))
    }

    func testMenuBarTitleFocusEnded() {
        sut.phase = .focusEnded
        XCTAssertEqual(sut.menuBarTitle, "Break?")
    }

    func testMenuBarTitleBreakEnded() {
        sut.phase = .breakEnded
        XCTAssertEqual(sut.menuBarTitle, "Done!")
    }

    // MARK: - Settings defaults

    func testDefaultFocusDuration() {
        XCTAssertEqual(sut.focusDuration, 25)
    }

    func testDefaultBreakDuration() {
        XCTAssertEqual(sut.breakDuration, 5)
    }

    func testDefaultLongBreakDuration() {
        XCTAssertEqual(sut.longBreakDuration, 15)
    }

    func testDefaultSessionsUntilLongBreak() {
        XCTAssertEqual(sut.sessionsUntilLongBreak, 4)
    }

    func testDefaultAutoStartBreak() {
        XCTAssertTrue(sut.autoStartBreak)
    }
}

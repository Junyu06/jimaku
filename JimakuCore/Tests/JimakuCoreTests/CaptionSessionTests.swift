import JimakuCore
import Testing

@Suite("CaptionSession")
struct CaptionSessionTests {
    private func session(in state: CaptionSession.State) -> CaptionSession {
        var session = CaptionSession()
        switch state {
        case .idle:
            break
        case .starting:
            session.requestStart()
        case .running:
            session.requestStart()
            session.windowDidStart()
        case .stopping:
            session.requestStart()
            session.windowDidStart()
            session.requestStop()
        }
        precondition(session.state == state)
        return session
    }

    // MARK: Starting

    @Test("A new session is idle and offers Start")
    func newSessionIsIdle() {
        let session = CaptionSession()
        #expect(session.state == .idle)
        #expect(session.primaryAction == .start)
        #expect(session.canPerformPrimaryAction)
        #expect(session.isActive == false)
    }

    @Test("Requesting a start waits for the window before running")
    func requestStartWaitsForWindow() {
        var session = CaptionSession()
        do { let result = session.requestStart(); #expect(result) }
        #expect(session.state == .starting)
        #expect(session.isActive)
        #expect(session.primaryAction == .stop)
    }

    @Test("The session runs once the window has started")
    func windowStartMakesItRun() {
        var session = session(in: .starting)
        session.windowDidStart()
        #expect(session.state == .running)
        #expect(session.isActive)
        #expect(session.primaryAction == .stop)
    }

    @Test("A window that fails to start returns the session to idle")
    func failedStartReturnsToIdle() {
        var session = session(in: .starting)
        session.windowFailedToStart()
        #expect(session.state == .idle)
        #expect(session.primaryAction == .start)
        #expect(session.canPerformPrimaryAction)
    }

    @Test("A second start request while starting or running is refused")
    func duplicateStartIsRefused() {
        var starting = session(in: .starting)
        do { let result = starting.requestStart(); #expect(result == false) }
        #expect(starting.state == .starting)
        var running = session(in: .running)
        do { let result = running.requestStart(); #expect(result == false) }
        #expect(running.state == .running)
    }

    // MARK: Stopping

    @Test("Requesting a stop waits for the window to close")
    func requestStopWaitsForWindow() {
        var session = session(in: .running)
        do { let result = session.requestStop(); #expect(result) }
        #expect(session.state == .stopping)
        #expect(session.isActive == false)
    }

    @Test("While stopping, Start is shown but cannot be used yet")
    func stoppingBlocksStart() {
        var session = session(in: .stopping)
        #expect(session.primaryAction == .start)
        #expect(session.canPerformPrimaryAction == false)
        do { let result = session.requestStart(); #expect(result == false) }
        do { let result = session.performPrimaryAction(); #expect(result == nil) }
        #expect(session.state == .stopping)
    }

    @Test("The session is idle again once the window has closed")
    func windowCloseFinishesStop() {
        var session = session(in: .stopping)
        session.windowDidClose()
        #expect(session.state == .idle)
        #expect(session.canPerformPrimaryAction)
    }

    @Test("A stop can be requested while the window is still starting")
    func stopWhileStarting() {
        var session = session(in: .starting)
        do { let result = session.requestStop(); #expect(result) }
        #expect(session.state == .stopping)
    }

    @Test("A window that starts after a stop was requested does not revive the session")
    func lateWindowStartStaysStopping() {
        var session = session(in: .starting)
        session.requestStop()
        session.windowDidStart()
        #expect(session.state == .stopping)
    }

    @Test("A window that fails to start after a stop was requested finishes the stop")
    func failedStartWhileStopping() {
        var session = session(in: .starting)
        session.requestStop()
        session.windowFailedToStart()
        #expect(session.state == .idle)
    }

    @Test("Stopping an idle session is refused")
    func stopWhenIdleIsRefused() {
        var session = CaptionSession()
        do { let result = session.requestStop(); #expect(result == false) }
        #expect(session.state == .idle)
    }

    // MARK: The window going away on its own

    @Test("The window closing while running ends the session")
    func windowCloseWhileRunning() {
        var session = session(in: .running)
        session.windowDidClose()
        #expect(session.state == .idle)
    }

    @Test("The window closing while starting ends the session")
    func windowCloseWhileStarting() {
        var session = session(in: .starting)
        session.windowDidClose()
        #expect(session.state == .idle)
    }

    @Test("Window events on an idle session change nothing")
    func windowEventsWhenIdle() {
        var session = CaptionSession()
        session.windowDidStart()
        session.windowFailedToStart()
        session.windowDidClose()
        #expect(session.state == .idle)
    }

    @Test("A failed-start report on a running session is ignored")
    func failedStartWhileRunningIsIgnored() {
        var session = session(in: .running)
        session.windowFailedToStart()
        #expect(session.state == .running)
    }

    // MARK: Stop, then start again

    @Test("A late close from the old window cannot end a new session, because the new one cannot begin before it")
    func restartWaitsForOldWindow() {
        var session = session(in: .running)
        session.requestStop()
        // The user taps Start again before the old window has finished closing.
        do { let result = session.requestStart(); #expect(result == false) }
        // The old window finishes closing.
        session.windowDidClose()
        #expect(session.state == .idle)
        // Now a new session can begin, and no stale close is left to end it.
        do { let result = session.requestStart(); #expect(result) }
        session.windowDidStart()
        #expect(session.state == .running)
    }

    // MARK: The primary action

    @Test("Performing the primary action starts an idle session and stops an active one")
    func performPrimaryAction() {
        var session = CaptionSession()
        do { let result = session.performPrimaryAction(); #expect(result == .start) }
        #expect(session.state == .starting)
        do { let result = session.performPrimaryAction(); #expect(result == .stop) }
        #expect(session.state == .stopping)
    }
}

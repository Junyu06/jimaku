import Testing

import JimakuCore

@Suite("CaptionSession")
struct CaptionSessionTests {
    @Test("A new session is idle")
    func newSessionIsIdle() {
        let session = CaptionSession()
        #expect(session.state == .idle)
    }

    @Test("Starting an idle session makes it run")
    func startMakesItRun() {
        var session = CaptionSession()
        session.start()
        #expect(session.state == .running)
    }

    @Test("Stopping a running session makes it idle again")
    func stopMakesItIdle() {
        var session = CaptionSession()
        session.start()
        session.stop()
        #expect(session.state == .idle)
    }

    @Test("Starting twice keeps the session running")
    func startTwiceStaysRunning() {
        var session = CaptionSession()
        session.start()
        session.start()
        #expect(session.state == .running)
    }

    @Test("Stopping an idle session keeps it idle")
    func stopWhenIdleStaysIdle() {
        var session = CaptionSession()
        session.stop()
        #expect(session.state == .idle)
    }

    @Test("Stopping twice keeps the session idle")
    func stopTwiceStaysIdle() {
        var session = CaptionSession()
        session.start()
        session.stop()
        session.stop()
        #expect(session.state == .idle)
    }

    @Test("A stopped session can be started again")
    func startAfterStopRunsAgain() {
        var session = CaptionSession()
        session.start()
        session.stop()
        session.start()
        #expect(session.state == .running)
    }

    @Test("The primary action is Start again after stopping")
    func primaryActionAfterStopIsStart() {
        var session = CaptionSession()
        session.start()
        session.stop()
        #expect(session.primaryAction == .start)
    }

    @Test("The primary action is Start when idle and Stop when running")
    func primaryActionFollowsState() {
        var session = CaptionSession()
        #expect(session.primaryAction == .start)
        session.start()
        #expect(session.primaryAction == .stop)
    }

    @Test("Performing the primary action toggles the session")
    func performPrimaryActionToggles() {
        var session = CaptionSession()
        session.performPrimaryAction()
        #expect(session.state == .running)
        session.performPrimaryAction()
        #expect(session.state == .idle)
    }
}

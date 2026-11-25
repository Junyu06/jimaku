import JimakuCore
import Testing

@Suite("RecordingExplanation")
struct RecordingExplanationTests {
    @Test("Before the first start that would go ahead, the explanation is due")
    func firstStart() {
        #expect(RecordingExplanation.isDueBeforeStart(readBefore: false, startWouldGoAhead: true))
    }

    @Test("Once it has been read, a start does not bring the explanation again")
    func readBefore() {
        #expect(!RecordingExplanation.isDueBeforeStart(readBefore: true, startWouldGoAhead: true))
    }

    @Test("A tap that would not start a session does not bring the explanation, read or not")
    func noStart() {
        #expect(!RecordingExplanation.isDueBeforeStart(readBefore: false, startWouldGoAhead: false))
        #expect(!RecordingExplanation.isDueBeforeStart(readBefore: true, startWouldGoAhead: false))
    }

    @Test("Closed with its button before a first session, with the app in front and no session, the page starts one")
    func startsAfterButton() {
        #expect(RecordingExplanation.startsSessionOnceGone(closedWithButtonBeforeStart: true, appIsActive: true, sessionIsIdle: true))
    }

    @Test("Closed any other way, the page starts nothing")
    func closedOtherwise() {
        #expect(!RecordingExplanation.startsSessionOnceGone(closedWithButtonBeforeStart: false, appIsActive: true, sessionIsIdle: true))
    }

    @Test("A user who has left the app by the time the page is gone gets no session")
    func leftTheApp() {
        #expect(!RecordingExplanation.startsSessionOnceGone(closedWithButtonBeforeStart: true, appIsActive: false, sessionIsIdle: true))
    }

    @Test("With a session already there when the page is gone, the page does not press the main button")
    func sessionNotIdle() {
        #expect(!RecordingExplanation.startsSessionOnceGone(closedWithButtonBeforeStart: true, appIsActive: true, sessionIsIdle: false))
    }
}

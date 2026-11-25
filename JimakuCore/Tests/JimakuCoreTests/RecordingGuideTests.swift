import JimakuCore
import Testing

@Suite("RecordingGuide")
struct RecordingGuideTests {
    private let everyAudio: [AudioAvailability] = [.unavailable, .notBroadcasting, .receiving, .stalled]

    @Test("Until the caption window is up the guide is nil, whatever the audio")
    func windowNotUp() {
        for audio in everyAudio {
            #expect(RecordingGuide.choose(windowIsUp: false, audio: audio) == nil)
        }
    }

    @Test("With the window up and no broadcast the guide is to open the recording")
    func noRecording() {
        #expect(RecordingGuide.choose(windowIsUp: true, audio: .notBroadcasting) == .openRecording)
    }

    @Test("With the window up and a broadcast that carries no sound the guide is that there is no sound")
    func noSound() {
        #expect(RecordingGuide.choose(windowIsUp: true, audio: .stalled) == .noSound)
    }

    @Test("With the window up and sound arriving the guide is nil")
    func receiving() {
        #expect(RecordingGuide.choose(windowIsUp: true, audio: .receiving) == nil)
    }

    @Test("With the window up and no shared audio the guide is that the app cannot hear")
    func cannotHear() {
        #expect(RecordingGuide.choose(windowIsUp: true, audio: .unavailable) == .cannotHear)
    }
}

@Suite("BroadcastSheetRequest")
struct BroadcastSheetRequestTests {
    private func owed(audio: AudioAvailability = .notBroadcasting, sessionWasStarting: Bool = true) -> BroadcastSheetRequest {
        var request = BroadcastSheetRequest()
        request.windowAppeared(sessionWasStarting: sessionWasStarting, audio: audio)
        return request
    }

    /// Takes with everything in favor unless said otherwise.
    private func take(
        _ request: inout BroadcastSheetRequest,
        sessionRunning: Bool = true,
        audio: AudioAvailability = .notBroadcasting,
        appIsActive: Bool = true
    ) -> Bool {
        request.take(sessionRunning: sessionRunning, audio: audio, appIsActive: appIsActive)
    }

    @Test("Nothing is owed before a window has appeared")
    func nothingAtFirst() {
        var request = BroadcastSheetRequest()
        #expect(request.isOwed == false)
        #expect(take(&request) == false)
    }

    @Test("A window that appears for a starting session with no broadcast leaves the sheet owed")
    func owedWhenWindowAppears() {
        #expect(owed().isOwed)
    }

    @Test("A window that appears while a broadcast runs, or with no shared audio, leaves nothing owed")
    func notOwedWithBroadcast() {
        #expect(owed(audio: .receiving).isOwed == false)
        #expect(owed(audio: .stalled).isOwed == false)
        #expect(owed(audio: .unavailable).isOwed == false)
    }

    @Test("A window reported for a session that was not starting leaves nothing owed")
    func reportedAgain() {
        #expect(owed(sessionWasStarting: false).isOwed == false)
    }

    @Test("What is owed is taken once")
    func takenOnce() {
        var request = owed()
        #expect(take(&request))
        #expect(request.isOwed == false)
        #expect(take(&request) == false)
    }

    @Test("A second report of the window after the sheet was taken does not make it owed again")
    func secondReportAfterTaking() {
        var request = owed()
        #expect(take(&request))
        request.windowAppeared(sessionWasStarting: false, audio: .notBroadcasting)
        #expect(request.isOwed == false)
    }

    @Test("Taken when the session no longer runs, a broadcast has started, or the app is not in front, it is dropped and not acted on")
    func droppedWhenNoLongerWanted() {
        var stopped = owed()
        #expect(take(&stopped, sessionRunning: false) == false)
        #expect(stopped.isOwed == false)

        var broadcasting = owed()
        #expect(take(&broadcasting, audio: .stalled) == false)
        #expect(broadcasting.isOwed == false)

        var away = owed()
        #expect(take(&away, appIsActive: false) == false)
        #expect(away.isOwed == false)
    }

    @Test("Dropped, what was owed is gone and is not taken later")
    func dropped() {
        var request = owed()
        request.drop()
        #expect(request.isOwed == false)
        #expect(take(&request) == false)
    }

    @Test("Dropping when nothing is owed changes nothing")
    func droppedWithNothingOwed() {
        var request = BroadcastSheetRequest()
        request.drop()
        #expect(request == BroadcastSheetRequest())
    }
}

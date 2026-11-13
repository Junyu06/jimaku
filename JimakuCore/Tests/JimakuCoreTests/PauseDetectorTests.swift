import Testing

@testable import JimakuCore

@Suite("PauseDetector")
struct PauseDetectorTests {
    private static let rate = 16_000

    /// A steady sound of the given level.
    private func sound(_ seconds: Double, level: Int16 = 8000) -> [Int16] {
        (0..<Int(seconds * Double(Self.rate))).map { $0.isMultiple(of: 2) ? level : -level }
    }

    private func quiet(_ seconds: Double) -> [Int16] { sound(seconds, level: 0) }

    /// Hands the batches to one detector, one after another, and says for each
    /// whether a pause began in it.
    private func pauses(in batches: [[Int16]]) -> [Bool] {
        var detector = PauseDetector(sampleRate: Self.rate)
        return batches.map { !detector.take($0).isEmpty }
    }

    @Test("Quiet alone is no pause")
    func quietAlone() {
        #expect(pauses(in: [quiet(2)]) == [false])
    }

    @Test("Speech that is still going on is no pause")
    func speechGoingOn() {
        #expect(pauses(in: [sound(2)]) == [false])
    }

    @Test("Quiet that lasts long enough after speech is a pause, reported once")
    func pauseAfterSpeech() {
        #expect(pauses(in: [sound(1), quiet(0.2), quiet(0.1), quiet(1)]) == [false, false, true, false])
    }

    @Test("A short gap inside speech is no pause")
    func shortGap() {
        #expect(pauses(in: [sound(1) + quiet(0.2) + sound(1), quiet(0.3)]) == [false, true])
    }

    @Test("Once the speaker has gone on for long, a shorter gap is a pause")
    func shorterPauseInLongSpeech() {
        #expect(pauses(in: [sound(3), quiet(0.2)]) == [false, true])
    }

    @Test("After a pause the next speech is measured from its own start")
    func nextSpeechStartsOver() {
        #expect(pauses(in: [sound(3) + quiet(0.3), sound(1) + quiet(0.2), quiet(0.1)]) == [true, false, true])
    }

    @Test("A click is not speech, so quiet after it is no pause")
    func click() {
        #expect(pauses(in: [sound(0.04) + quiet(1)]) == [false])
    }

    @Test("Sound much quieter than the speech before it counts as quiet")
    func quietIsRelative() {
        #expect(pauses(in: [sound(1) + sound(0.3, level: 300)]) == [true])
    }

    @Test("Speech over a steady sound that stays loud gives no pause")
    func speechOverMusic() {
        #expect(pauses(in: [sound(1) + sound(1, level: 3000) + sound(1)]) == [false])
    }

    @Test("A pause is placed at the sample where the quiet had lasted long enough")
    func placeOfAPause() {
        var detector = PauseDetector(sampleRate: Self.rate)
        // One second of speech and 0.3 seconds of quiet end at sample 20,800.
        #expect(detector.take(sound(1) + quiet(1)) == [20_800])
    }

    @Test("Several pauses in one batch are each reported, in order")
    func severalPausesInOneBatch() {
        var detector = PauseDetector(sampleRate: Self.rate)
        let audio = sound(0.4) + quiet(0.3) + sound(0.4) + quiet(0.3) + sound(0.6)
        #expect(detector.take(audio) == [11_200, 22_400])
    }

    @Test("A pause that ends in a later batch is placed within that batch")
    func pauseAcrossBatches() {
        var detector = PauseDetector(sampleRate: Self.rate)
        #expect(detector.take(sound(1) + quiet(0.2)).isEmpty)
        #expect(detector.take(quiet(0.5)) == [1_600])
    }

    @Test("No samples, no pause")
    func noSamples() {
        var detector = PauseDetector(sampleRate: Self.rate)
        #expect(detector.take([]).isEmpty)
        #expect(detector.take(sound(1)).isEmpty)
        #expect(detector.take([]).isEmpty)
    }

    @Test("Samples handed over in small batches give the same pauses")
    func smallBatches() {
        let audio = sound(1) + quiet(0.4) + sound(0.5) + quiet(0.4) + sound(3) + quiet(0.25)
        let batches = stride(from: 0, to: audio.count, by: 137).map {
            Array(audio[$0..<min($0 + 137, audio.count)])
        }
        var whole = PauseDetector(sampleRate: Self.rate)
        #expect(whole.take(audio).count == 3)
        #expect(pauses(in: batches).filter { $0 }.count == 3)
    }

    @Test("A recognizer that has heard into the quiet of a pause has all the speech before it")
    func heardIntoTheQuiet() {
        // What a device showed during a broadcast: with the audio up to a pause
        // handed over, the recognizer's range stopped 0.093 s short of it, and
        // once 0.112 s short, for as long as nothing more was handed over.
        #expect(PauseDetector.hasSpeech(before: 7.26, heardTo: 7.167))
        #expect(PauseDetector.hasSpeech(before: 5.34, heardTo: 5.228))
        #expect(PauseDetector.hasSpeech(before: 5.34, heardTo: 5.34))
    }

    @Test("A recognizer that has not reached the quiet of a pause may lack speech before it")
    func notYetIntoTheQuiet() {
        // The quiet is only known to have lasted `pauseInLongSpeech`.
        #expect(!PauseDetector.hasSpeech(before: 5.34, heardTo: 5.34 - PauseDetector.pauseInLongSpeech))
        #expect(!PauseDetector.hasSpeech(before: 5.34, heardTo: 4))
    }

    @Test("Hearing to the end of the speech is not enough at the shortest pause, hearing a little into its quiet is")
    func shortestPauseHeardInto() {
        var detector = PauseDetector(sampleRate: Self.rate)
        // Long speech, so 0.2 seconds of quiet make the pause, at 3.2 seconds.
        let places = detector.take(sound(3) + quiet(0.1)) + detector.take(quiet(0.1)).map { $0 + 49_600 }
        #expect(places == [51_200])
        let pause = Double(places[0]) / Double(Self.rate)
        #expect(!PauseDetector.hasSpeech(before: pause, heardTo: 3.0))
        #expect(!PauseDetector.hasSpeech(before: pause, heardTo: 3.03))
        #expect(PauseDetector.hasSpeech(before: pause, heardTo: 3.05))
    }

    @Test("What a recognizer may lack before a pause is between 0.15 and 0.17 seconds")
    func whatMayBeLacking() {
        #expect(PauseDetector.hasSpeech(before: 10, heardTo: 10 - 0.15))
        #expect(!PauseDetector.hasSpeech(before: 10, heardTo: 10 - 0.17))
    }
}

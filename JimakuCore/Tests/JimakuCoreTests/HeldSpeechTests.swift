import JimakuCore
import Testing

// The sentences here were written for these tests.
@Suite("HeldSpeech")
struct HeldSpeechTests {
    @Test("With nothing held, what the recognizer says passes through")
    func passesThrough() {
        var held = HeldSpeech()
        #expect(held.take(.partial("今日は"), endingAt: nil) == .partial("今日は"))
        #expect(held.take(.final("今日はいい天気。"), endingAt: 2) == .final("今日はいい天気。"))
        #expect(held.text.isEmpty)
    }

    @Test("A final result that answers a possible pause is held and shown as speech in progress, without its full stop")
    func holdsTheAnswer() {
        var held = HeldSpeech()
        held.asked(at: 3.2)
        #expect(held.take(.final("だから。"), endingAt: 3.08) == .partial("だから"))
        #expect(held.text == "だから。")
    }

    @Test("When the pause is certain, what was held is final, with its mark")
    func confirmReleases() {
        var held = HeldSpeech()
        held.asked(at: 3.2)
        _ = held.take(.final("少し待ってください。"), endingAt: 3.2)
        #expect(held.confirm(at: 3.3) == .final("少し待ってください。"))
        #expect(held.text.isEmpty)
        #expect(held.confirm(at: 3.4) == nil)
    }

    @Test("When the speaker goes on, the new speech follows what was held, and both end as one")
    func goesOn() {
        var held = HeldSpeech()
        held.asked(at: 3.2)
        _ = held.take(.final("だから。"), endingAt: 3.2)
        #expect(held.take(.partial("明日は"), endingAt: nil) == .partial("だから明日は"))
        held.asked(at: 5)
        #expect(held.take(.final("明日は傘を持っていく。"), endingAt: 5) == .partial("だから明日は傘を持っていく"))
        #expect(held.confirm(at: 5.1) == .final("だから明日は傘を持っていく。"))
    }

    @Test("Held English and what follows it are joined with a space")
    func english() {
        var held = HeldSpeech()
        held.asked(at: 1)
        #expect(held.take(.final("Well."), endingAt: 1) == .partial("Well"))
        #expect(held.take(.partial("I think"), endingAt: nil) == .partial("Well I think"))
        held.asked(at: 2)
        _ = held.take(.final("I think so."), endingAt: 2)
        #expect(held.confirm(at: 2.1) == .final("Well I think so."))
    }

    @Test("A question mark on what was held is kept when the speaker goes on")
    func questionMarkStays() {
        var held = HeldSpeech()
        held.asked(at: 1)
        #expect(held.take(.final("あれ？"), endingAt: 1) == .partial("あれ？"))
        held.asked(at: 2)
        _ = held.take(.final("どこだっけ。"), endingAt: 2)
        #expect(held.confirm(at: 2.1) == .final("あれ？どこだっけ。"))
    }

    @Test("A final result that comes after its pause was found certain is final at once")
    func lateAnswer() {
        var held = HeldSpeech()
        held.asked(at: 3.2)
        #expect(held.confirm(at: 3.2) == nil)
        #expect(held.take(.final("はい。"), endingAt: 3.1) == .final("はい。"))
    }

    @Test("A late answer to a pause that is certain is not taken for the answer to a newer possible pause")
    func lateAnswerToAnOlderPause() {
        var held = HeldSpeech()
        held.asked(at: 1.2)
        #expect(held.confirm(at: 1.3) == nil)
        held.asked(at: 2.2)
        #expect(held.take(.final("Earlier."), endingAt: 1.1) == .final("Earlier."))
        // The answer to the newer one is still held.
        #expect(held.take(.final("Later."), endingAt: 2.1) == .partial("Later"))
    }

    @Test("When a pause is certain while the recognizer still owes an answer, what was held waits and ends with that answer")
    func certainBeforeTheAnswer() {
        var held = HeldSpeech()
        held.asked(at: 1.2)
        _ = held.take(.final("Well."), endingAt: 1.1)
        _ = held.take(.partial("Yes. More words"), endingAt: nil)
        held.asked(at: 2.7)
        #expect(held.confirm(at: 2.8) == nil)
        #expect(held.text == "Well.")
        #expect(held.take(.final("Yes. More words."), endingAt: 2.6) == .final("Well Yes. More words."))
        #expect(held.text.isEmpty)
        #expect(held.overdue(at: 9) == nil)
    }

    @Test("What was held waits for an owed answer also when the recognizer reported nothing of the new speech beforehand")
    func certainBeforeAnAnswerWithNoGuess() {
        var held = HeldSpeech()
        held.asked(at: 1.2)
        _ = held.take(.final("I think."), endingAt: 1.1)
        // The speaker went on at once; no guess came before the next quiet.
        held.asked(at: 1.62)
        #expect(held.confirm(at: 1.72) == nil)
        #expect(held.take(.final("we should go."), endingAt: 1.52) == .final("I think we should go."))
    }

    @Test("When both answers come after the pause is certain, the two parts still end as one")
    func bothAnswersAfterThePauseIsCertain() {
        var held = HeldSpeech()
        var transcript = Transcript(rules: .english)
        func give(_ update: RecognitionUpdate?, at time: Double) {
            if let update { _ = transcript.apply(update, at: time) }
        }
        // A short quiet, the speaker goes on, another short quiet that becomes
        // certain, and only then the recognizer's two answers.
        held.asked(at: 1.2)
        held.asked(at: 1.62)
        give(held.confirm(at: 1.72), at: 0)
        give(held.take(.final("I think."), endingAt: 1.1), at: 0.05)
        give(held.take(.final("we should go."), endingAt: 1.52), at: 0.1)
        #expect(transcript.entries.map(\.original) == ["I think we should go."])
        #expect(held.text.isEmpty)
    }

    @Test("While the recognizer has unfinalized speech, an overdue answer is waited for; once that speech is withdrawn, what was held ends")
    func overdueWaitsForSpeechInProgress() {
        var held = HeldSpeech()
        held.asked(at: 1.2)
        _ = held.take(.final("Well."), endingAt: 1.1)
        _ = held.take(.partial("uh"), endingAt: nil)
        held.asked(at: 2.7)
        #expect(held.confirm(at: 2.8) == nil)
        #expect(held.overdue(at: 3.2) == nil)
        // The recognizer takes its guess back: there was nothing after all.
        #expect(held.take(.partial(""), endingAt: nil) == .partial("Well"))
        #expect(held.overdue(at: 3.3) == .final("Well."))
    }

    @Test("If the owed answer does not come, as after a knock, what was held ends 0.3 seconds of audio after the pause was certain")
    func owedAnswerNeverComes() {
        var held = HeldSpeech()
        held.asked(at: 1.2)
        _ = held.take(.final("Well."), endingAt: 1.1)
        held.asked(at: 2.7)
        #expect(held.confirm(at: 2.8) == nil)
        #expect(held.overdue(at: 3.0) == nil)
        #expect(held.overdue(at: 3.1) == .final("Well."))
        #expect(held.overdue(at: 3.2) == nil)
        #expect(held.text.isEmpty)
    }

    @Test("Nothing is overdue when nothing was held or no pause was certain")
    func nothingOverdue() {
        var held = HeldSpeech()
        #expect(held.overdue(at: 5) == nil)
        held.asked(at: 1.2)
        _ = held.take(.final("Well."), endingAt: 1.1)
        // Only a possible pause so far: the speaker may go on.
        #expect(held.overdue(at: 60) == nil)
        #expect(held.text == "Well.")
    }

    @Test("A final result the recognizer gave by itself is final at once, with what was held before it")
    func recognizersOwnFinal() {
        var held = HeldSpeech()
        held.asked(at: 3.2)
        _ = held.take(.final("だから。"), endingAt: 3.2)
        // Speech went on for seconds; this result ends far past the pause asked about.
        #expect(held.take(.final("明日は傘を持っていく。"), endingAt: 9) == .final("だから明日は傘を持っていく。"))
        #expect(held.text.isEmpty)
    }

    @Test("A final result whose place in the audio is not known is final at once")
    func unknownPlace() {
        var held = HeldSpeech()
        held.asked(at: 3.2)
        #expect(held.take(.final("はい。"), endingAt: nil) == .final("はい。"))
    }

    @Test("A final result with nothing said in it holds nothing")
    func emptyFinal() {
        var held = HeldSpeech()
        held.asked(at: 1)
        #expect(held.take(.final(""), endingAt: 1) == .partial(""))
        #expect(held.confirm(at: 1.1) == nil)
    }

    @Test("A late answer to an older possible pause does not settle a newer one that is still unanswered")
    func olderAnswerNewerRequest() {
        var held = HeldSpeech()
        held.asked(at: 1.2)
        _ = held.take(.final("Well."), endingAt: 1.1)
        _ = held.take(.partial("I think"), endingAt: nil)
        held.asked(at: 2.2)
        // The speaker goes on; before the recognizer answers, another short quiet.
        held.asked(at: 3.2)
        #expect(held.take(.final("I think."), endingAt: 2.0) == .partial("Well I think"))
        #expect(held.confirm(at: 3.3) == nil)
        #expect(held.take(.final("so."), endingAt: 3.1) == .final("Well I think so."))
    }

    @Test("An answer that ends just after an older possible pause is not taken for the answer to the newest")
    func olderAnswerEndingJustAfterItsPause() {
        var held = HeldSpeech()
        held.asked(at: 1.2)
        // Two possible pauses are at least 0.22 seconds apart.
        held.asked(at: 1.42)
        #expect(held.take(.final("One."), endingAt: 1.24) == .partial("One"))
        #expect(held.confirm(at: 1.52) == nil)
        #expect(held.take(.final("two."), endingAt: 1.4) == .final("One two."))
    }

    @Test("An answer may end up to 0.16 seconds before the possible pause it answers")
    func answerEndsABitEarly() {
        var held = HeldSpeech()
        held.asked(at: 3.2)
        // On a device the recognizer's result stops short of the audio handed over.
        _ = held.take(.final("はい。"), endingAt: 3.05)
        #expect(held.confirm(at: 3.3) == .final("はい。"))
    }

    @Test("Several short quiets in one sentence make one piece")
    func severalShortQuiets() {
        var held = HeldSpeech()
        held.asked(at: 1)
        _ = held.take(.final("One."), endingAt: 1)
        held.asked(at: 2)
        _ = held.take(.final("two."), endingAt: 2)
        held.asked(at: 3)
        #expect(held.take(.final("three."), endingAt: 3) == .partial("One two three"))
        #expect(held.confirm(at: 3.1) == .final("One two three."))
    }

    @Test("What is held when an answer never comes is still kept by the transcript, once, and not said again later")
    func answerNeverComes() {
        var held = HeldSpeech()
        var transcript = Transcript(rules: .english)
        func give(_ update: RecognitionUpdate?, at time: Double) {
            if let update { _ = transcript.apply(update, at: time) }
        }
        held.asked(at: 1.2)
        give(held.take(.final("Well."), endingAt: 1.1), at: 0)
        give(held.take(.partial("I think"), endingAt: nil), at: 0.5)
        held.asked(at: 2.2)
        give(held.confirm(at: 2.3), at: 1.6)
        #expect(held.text == "Well.")
        // No answer. The transcript keeps what it has when nothing changes for long.
        _ = transcript.elapse(to: 10)
        #expect(transcript.entries.map(\.original).joined(separator: " ").filter(\.isLetter) == "WellIthink")
        // The recognizer still has "I think" unfinalized, so what is said next
        // comes after it. It is its own caption.
        give(held.take(.partial("I think Hello"), endingAt: nil), at: 11)
        held.asked(at: 12)
        give(held.take(.final("I think Hello there."), endingAt: 12), at: 12)
        give(held.confirm(at: 12.1), at: 12.1)
        #expect(transcript.entries.map(\.original).joined(separator: " ").filter(\.isLetter) == "WellIthinkHellothere")
    }

    @Test("Through the transcript, an older answer and a newer request make one piece, each word once")
    func olderAnswerThroughTheTranscript() {
        var held = HeldSpeech()
        var transcript = Transcript(rules: .english)
        func give(_ update: RecognitionUpdate?, at time: Double) {
            if let update { _ = transcript.apply(update, at: time) }
        }
        held.asked(at: 1.2)
        give(held.take(.final("Well."), endingAt: 1.1), at: 0)
        give(held.take(.partial("I think"), endingAt: nil), at: 0.4)
        held.asked(at: 2.2)
        held.asked(at: 3.2)
        give(held.take(.final("I think."), endingAt: 2.0), at: 0.9)
        give(held.take(.partial("so"), endingAt: nil), at: 0.95)
        give(held.confirm(at: 3.3), at: 1.0)
        give(held.take(.final("so."), endingAt: 3.1), at: 1.1)
        #expect(transcript.entries.map(\.original) == ["Well I think so."])
    }

    @Test("Through the transcript, a pause found certain before its answer neither repeats nor loses a word")
    func noWordTwice() {
        var held = HeldSpeech()
        var transcript = Transcript(rules: .english)
        func give(_ update: RecognitionUpdate?, at time: Double) {
            if let update { _ = transcript.apply(update, at: time) }
        }
        held.asked(at: 1.2)
        give(held.take(.final("Well."), endingAt: 1.1), at: 0)
        give(held.take(.partial("Yes. More"), endingAt: nil), at: 0.35)
        give(held.take(.partial("Yes. More words"), endingAt: nil), at: 1.2)
        held.asked(at: 2.7)
        give(held.confirm(at: 2.8), at: 1.55)
        give(held.take(.final("Yes. More words."), endingAt: 2.6), at: 1.65)
        let said = transcript.entries.map(\.original).joined(separator: " ")
        #expect(said.filter(\.isLetter) == "WellYesMorewords")
        #expect(transcript.pending.isEmpty)
    }
}

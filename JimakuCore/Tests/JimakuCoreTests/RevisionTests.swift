import JimakuCore
import Testing

/// The recognizer may rewrite text it has already reported, including text whose
/// sentences were already handed out for translation. Until a stretch of speech is
/// final, its sentences follow the recognizer's latest guess, so nothing can be lost
/// or repeated. Most sequences here were found in review by probing.
@Suite("Transcript follows the recognizer's latest guess")
struct TranscriptFollowsLatestGuessTests {
    /// Rewrites of one stretch, each ending in a final result.
    static let stretches: [[String]] = [
        ["Hello. world", "Hello world", "Hello world."],
        ["One. Two. Three", "One two. Three", "One two. Three. Four", "One two. Three. Four."],
        ["One two. Three", "One. Two. Three", "One. Two. Three."],
        ["It costs 3.", "It costs 3.5 dollars", "It costs 3.5 dollars."],
        ["そうです。はい", "そうです。はい、そうです。次", "そうです。はい、そうです。次です。"],
        ["そうです。はい", "そうですはい", "そうですはい。"],
        ["そうです。はい", "そう。はい", "そう。はい。"],
        ["Good morning. Hello", "Hi. Hello", "Hi. Hello."],
        ["Hi. world", "Hello. world", "Hello. world."],
        ["Good morning. Hello", "Hi. Hello there. How", "Hi. Hello there. How are you."],
        ["そうです。は", "そう。は", "そう。はい。"],
        ["はい。そう", "そうですね。そう", "そうですね。そう。"],
        ["Hi. go", "You go. go now", "You go. go now."],
        ["Hi. he", "They agreed. he", "They agreed. he."],
        ["Good morning.", "Hi. Hello", "Hi. Hello."],
        ["そうです。はい", "そう。ええ", "そう。ええ。"],
        ["Good morning. Hello", "Good", "Hi. Hello", "Hi. Hello."],
    ]

    private func sentences(of text: String) -> [String] {
        let split = CaptionText.sentences(in: text)
        return split.remainder.isEmpty ? split.complete : split.complete + [split.remainder]
    }

    @Test("After every guess, the sentences and the speech in progress are exactly that guess", arguments: stretches)
    func partialsMatchTheGuess(stretch: [String]) {
        var transcript = Transcript()
        for guess in stretch.dropLast() {
            transcript.apply(.partial(guess))
            let split = CaptionText.sentences(in: guess)
            #expect(transcript.entries.map(\.original) == split.complete)
            #expect(transcript.pending == split.remainder)
        }
    }

    @Test("After the final result, the sentences are exactly the final text", arguments: stretches)
    func finalMatchesTheText(stretch: [String]) {
        var transcript = Transcript()
        for guess in stretch.dropLast() { transcript.apply(.partial(guess)) }
        transcript.apply(.final(stretch.last!))
        #expect(transcript.entries.map(\.original) == sentences(of: stretch.last!))
        #expect(transcript.pending.isEmpty)
    }

    @Test("A finished stretch is not touched by the next one", arguments: stretches)
    func earlierStretchIsKept(stretch: [String]) {
        var transcript = Transcript()
        transcript.apply(.final("Earlier one. Earlier two."))
        for guess in stretch.dropLast() { transcript.apply(.partial(guess)) }
        transcript.apply(.final(stretch.last!))
        #expect(transcript.entries.map(\.original) == ["Earlier one.", "Earlier two."] + sentences(of: stretch.last!))
        #expect(transcript.entries.map(\.id) == Array(0..<transcript.entries.count))
    }

    @Test("A guess that shrinks and grows again keeps following it")
    func shrinkThenGrow() {
        var transcript = Transcript()
        transcript.apply(.partial("One. Two"))
        transcript.apply(.partial("One."))
        #expect(transcript.pending.isEmpty)
        transcript.apply(.partial("One. Two again"))
        #expect(transcript.entries.map(\.original) == ["One."])
        #expect(transcript.pending == "Two again")
    }
}

@Suite("Translations under revision")
struct TranslationsUnderRevisionTests {
    @Test("Only new or rewritten sentences are handed out for translation")
    func onlyChangedSentencesAreHandedOut() {
        var transcript = Transcript()
        #expect(transcript.apply(.partial("One. Two")).map(\.original) == ["One."])
        #expect(transcript.apply(.partial("One. Two. Three")).map(\.original) == ["Two."])
        #expect(transcript.apply(.partial("One. Two. Three is")).isEmpty)
        #expect(transcript.apply(.partial("One. Too. Three is")).map(\.original) == ["Too."])
        #expect(transcript.apply(.final("One. Too. Three is here.")).map(\.original) == ["Three is here."])
    }

    @Test("A sentence that did not change keeps its translation")
    func unchangedSentenceKeepsTranslation() {
        var transcript = Transcript()
        let first = transcript.apply(.partial("One. Two"))[0]
        transcript.setTranslation("一。", for: first)
        transcript.apply(.partial("One. Two. Three"))
        transcript.apply(.final("One. Two. Three."))
        #expect(transcript.entries[0].translation == "一。")
    }

    @Test("A rewritten sentence loses its old translation")
    func rewrittenSentenceLosesTranslation() {
        var transcript = Transcript()
        let first = transcript.apply(.partial("Won. Two"))[0]
        transcript.setTranslation("赢了。", for: first)
        transcript.apply(.partial("One. Two"))
        #expect(transcript.entries[0].original == "One.")
        #expect(transcript.entries[0].translation == nil)
    }

    @Test("A translation that arrives for a sentence since rewritten is ignored")
    func lateTranslationOfRewrittenSentence() {
        var transcript = Transcript()
        let old = transcript.apply(.partial("Won. Two"))[0]
        transcript.apply(.partial("One. Two"))
        transcript.setTranslation("赢了。", for: old)
        #expect(transcript.entries[0].translation == nil)
    }

    @Test("A sentence pushed to a later position by a rewrite keeps its translation")
    func movedSentenceKeepsTranslation() {
        var transcript = Transcript()
        let hello = transcript.apply(.partial("Hello there. How"))[0]
        transcript.setTranslation("你好。", for: hello)
        let handedOut = transcript.apply(.partial("Well. Hello there. How"))
        #expect(handedOut.map(\.original) == ["Well."])
        #expect(transcript.entries.map(\.translation) == [nil, "你好。"])
    }

    @Test("A translation arriving after its sentence moved still reaches it")
    func lateTranslationOfMovedSentence() {
        var transcript = Transcript()
        let hello = transcript.apply(.partial("Hello there. How"))[0]
        transcript.apply(.partial("Well. Hello there. How"))
        transcript.setTranslation("你好。", for: hello)
        #expect(transcript.entries.map(\.translation) == [nil, "你好。"])
    }

    @Test("Once a stretch is final its translations are no longer revised")
    func finalStretchKeepsTranslations() {
        var transcript = Transcript()
        let first = transcript.apply(.final("One."))[0]
        transcript.setTranslation("一。", for: first)
        transcript.apply(.partial("Two. Three"))
        #expect(transcript.entries[0] == Transcript.Entry(id: 0, original: "One.", translation: "一。"))
    }
}

@Suite("Sentence endings in English")
struct EnglishSentenceEndingTests {
    @Test("A title before a name does not end a sentence")
    func titles() {
        #expect(CaptionText.sentences(in: "Dr. Smith is here").complete.isEmpty)
        #expect(CaptionText.sentences(in: "Ask Mr. Lee. He knows").complete == ["Ask Mr. Lee."])
    }

    @Test("Three periods are a pause, not an ending")
    func asciiEllipsis() {
        #expect(CaptionText.sentences(in: "Wait... maybe").complete.isEmpty)
    }

    @Test("A period right after a digit at the very end may be a decimal point still to come")
    func trailingPeriodAfterDigit() {
        let split = CaptionText.sentences(in: "It costs 3.")
        #expect(split.complete.isEmpty)
        #expect(split.remainder == "It costs 3.")
    }

    @Test("The split reports how many characters the finished sentences took")
    func consumedCount() {
        #expect(CaptionText.sentences(in: "One. Two").consumed == 5)
        #expect(CaptionText.sentences(in: "One two").consumed == 0)
        #expect(CaptionText.sentences(in: "そうです。はい").consumed == 5)
    }
}

@Suite("TranslationPipeline after review")
struct TranslationPipelineReviewTests {
    private func entry(_ id: Int) -> Transcript.Entry {
        Transcript.Entry(id: id, original: "sentence \(id)", translation: nil)
    }

    @Test("The same words spoken again later are translated again")
    func repeatedClauseIsTranslatedAgain() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.offerPending("How are you")
        #expect(pipeline.takeNext() == .pending("How are you"))
        pipeline.finishCurrent()
        pipeline.offerPending("")
        pipeline.offerPending("How are you")
        #expect(pipeline.takeNext() == .pending("How are you"))
    }

    @Test("A translation that fails makes translation unavailable until one succeeds")
    func failureAndRecovery() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.settle(entry(0))
        pipeline.settle(entry(1))
        _ = pipeline.takeNext()
        pipeline.finishCurrent(succeeded: false)
        #expect(pipeline.isTranslationAvailable == false)
        // It keeps trying, so it can recover.
        #expect(pipeline.takeNext() == .entry(entry(1)))
        pipeline.finishCurrent(succeeded: true)
        #expect(pipeline.isTranslationAvailable)
    }

    @Test("A provisional translation that fails also makes translation unavailable")
    func pendingFailure() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.offerPending("How are you doing")
        _ = pipeline.takeNext()
        pipeline.finishCurrent(succeeded: false)
        #expect(pipeline.isTranslationAvailable == false)
    }

    @Test("A provisional translation that succeeds restores availability")
    func pendingSuccessRecovers() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.settle(entry(0))
        _ = pipeline.takeNext()
        pipeline.finishCurrent(succeeded: false)
        pipeline.offerPending("How are you doing")
        #expect(pipeline.takeNext() == .pending("How are you doing"))
        pipeline.finishCurrent(succeeded: true)
        #expect(pipeline.isTranslationAvailable)
    }

    @Test("After a failure the same speech in progress is offered again, so translation can recover")
    func pendingRetriedAfterFailure() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.offerPending("How are you doing")
        _ = pipeline.takeNext()
        pipeline.finishCurrent(succeeded: false)
        pipeline.offerPending("How are you doing")
        #expect(pipeline.takeNext() == .pending("How are you doing"))
    }

    @Test("Preparing a translator again clears an earlier failure")
    func preparingClearsFailure() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.settle(entry(0))
        _ = pipeline.takeNext()
        pipeline.finishCurrent(succeeded: false)
        pipeline.setReadiness(.preparing)
        #expect(pipeline.isTranslationAvailable)
    }
}

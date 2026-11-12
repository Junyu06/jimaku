import JimakuCore
import Testing

/// The recognizer may rewrite text it has already reported. These cases were found in
/// review by probing the transcript with such rewrites.
@Suite("Transcript under revision")
struct TranscriptRevisionTests {
    private func originals(_ updates: [RecognitionUpdate]) -> [String] {
        var transcript = Transcript()
        for update in updates { transcript.apply(update) }
        return transcript.entries.map(\.original)
    }

    @Test("Removing a sentence boundary does not lose the words after it")
    func boundaryRemoved() {
        #expect(originals([.partial("Hello. world"), .partial("Hello world"), .final("Hello world.")]) == ["Hello.", "world."])
    }

    @Test("While a boundary is being removed, the row does not repeat settled words")
    func boundaryRemovedRow() {
        var transcript = Transcript()
        transcript.apply(.partial("Hello. world"))
        transcript.apply(.partial("Hello world"))
        #expect(transcript.currentLines.original == "Hello. world")
    }

    @Test("Merging two settled sentences does not lose the one that follows")
    func sentencesMerged() {
        let result = originals([
            .partial("One. Two. Three"),
            .partial("One two. Three"),
            .partial("One two. Three. Four"),
            .final("One two. Three. Four."),
        ])
        #expect(result == ["One.", "Two.", "Three.", "Four."])
    }

    @Test("Splitting a settled sentence does not settle part of it again")
    func sentenceSplit() {
        #expect(originals([.partial("One two. Three"), .partial("One. Two. Three"), .final("One. Two. Three.")]) == ["One two.", "Three."])
    }

    @Test("A number still being spoken is not cut at its decimal point")
    func decimalInProgress() {
        #expect(originals([.partial("It costs 3."), .partial("It costs 3.5 dollars"), .final("It costs 3.5 dollars.")]) == ["It costs 3.5 dollars."])
    }

    @Test("A guess that shrinks and grows again settles nothing twice")
    func shrinkThenGrow() {
        var transcript = Transcript()
        transcript.apply(.partial("One. Two"))
        transcript.apply(.partial("One."))
        #expect(transcript.pending.isEmpty)
        transcript.apply(.partial("One. Two again"))
        #expect(transcript.entries.map(\.original) == ["One."])
        #expect(transcript.pending == "Two again")
    }

    @Test("Japanese text rewritten before the settled point keeps what follows")
    func japaneseRevision() {
        let result = originals([.partial("そうです。はい"), .partial("そうです。はい、そうです。次"), .final("そうです。はい、そうです。次です。")])
        #expect(result == ["そうです。", "はい、そうです。", "次です。"])
    }
}

/// More rewrites found in the second review: the settled part itself changes length.
@Suite("Transcript when the settled part is rewritten")
struct TranscriptSettledPartRewrittenTests {
    private func originals(_ updates: [RecognitionUpdate]) -> [String] {
        var transcript = Transcript()
        for update in updates { transcript.apply(update) }
        return transcript.entries.map(\.original)
    }

    @Test("Japanese: a removed sentence mark does not cost the next character")
    func japaneseMarkRemoved() {
        #expect(originals([.partial("そうです。はい"), .partial("そうですはい"), .final("そうですはい。")]) == ["そうです。", "はい。"])
    }

    @Test("Japanese: a shortened settled sentence does not cost what follows")
    func japaneseSettledShortened() {
        #expect(originals([.partial("そうです。はい"), .partial("そう。はい"), .final("そう。はい。")]) == ["そうです。", "はい。"])
    }

    @Test("English: a shortened settled sentence does not cost what follows")
    func englishSettledShortened() {
        #expect(originals([.partial("Good morning. Hello"), .partial("Hi. Hello"), .final("Hi. Hello.")]) == ["Good morning.", "Hello."])
    }

    @Test("English: a lengthened settled sentence is not settled again")
    func englishSettledLengthened() {
        #expect(originals([.partial("Hi. world"), .partial("Hello. world"), .final("Hello. world.")]) == ["Hi.", "world."])
    }

    @Test("A rewrite of the settled part followed by more speech keeps going from the right place")
    func rewriteThenGrowth() {
        let result = originals([
            .partial("Good morning. Hello"),
            .partial("Hi. Hello there. How"),
            .final("Hi. Hello there. How are you."),
        ])
        #expect(result == ["Good morning.", "Hello there.", "How are you."])
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

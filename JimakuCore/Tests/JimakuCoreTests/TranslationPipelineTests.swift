import JimakuCore
import Testing

@Suite("TranslationPipeline")
struct TranslationPipelineTests {
    private func entry(_ id: Int) -> Transcript.Entry {
        Transcript.Entry(id: id, original: "sentence \(id)", translation: nil)
    }

    @Test("Nothing is handed out while the translator is still preparing")
    func waitsForTranslator() {
        var pipeline = TranslationPipeline()
        pipeline.settle(entry(0))
        #expect(pipeline.takeNext() == nil)
    }

    @Test("A sentence settled before the translator was ready is translated once it is")
    func earlySentenceIsNotLost() {
        var pipeline = TranslationPipeline()
        pipeline.settle(entry(0))
        pipeline.setReadiness(.ready)
        #expect(pipeline.takeNext() == .entry(entry(0)))
    }

    @Test("Only one sentence is translated at a time, in order")
    func oneAtATime() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.settle(entry(0))
        pipeline.settle(entry(1))
        #expect(pipeline.takeNext() == .entry(entry(0)))
        #expect(pipeline.takeNext() == nil)
        pipeline.finishCurrent()
        #expect(pipeline.takeNext() == .entry(entry(1)))
        pipeline.finishCurrent()
        #expect(pipeline.takeNext() == nil)
    }

    @Test("While waiting, the oldest sentences are dropped beyond the limit")
    func boundedWhileWaiting() {
        var pipeline = TranslationPipeline(limit: 2)
        pipeline.settle(entry(0))
        pipeline.settle(entry(1))
        pipeline.settle(entry(2))
        pipeline.setReadiness(.ready)
        #expect(pipeline.takeNext() == .entry(entry(1)))
        pipeline.finishCurrent()
        #expect(pipeline.takeNext() == .entry(entry(2)))
    }

    @Test("Nothing is handed out after the translator failed")
    func failedTranslator() {
        var pipeline = TranslationPipeline()
        pipeline.settle(entry(0))
        pipeline.setReadiness(.failed)
        #expect(pipeline.takeNext() == nil)
        #expect(pipeline.isTranslationAvailable == false)
    }

    @Test("Translation counts as available while preparing and when ready")
    func availability() {
        var pipeline = TranslationPipeline()
        #expect(pipeline.isTranslationAvailable)
        pipeline.setReadiness(.ready)
        #expect(pipeline.isTranslationAvailable)
    }

    @Test("Switching translators keeps what was waiting and frees the slot")
    func switchingTranslators() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.settle(entry(0))
        pipeline.settle(entry(1))
        _ = pipeline.takeNext()
        // The engine changes while sentence 0 is with the old translator.
        pipeline.setReadiness(.preparing)
        #expect(pipeline.takeNext() == nil)
        pipeline.setReadiness(.ready)
        #expect(pipeline.takeNext() == .entry(entry(1)))
    }

    // MARK: Speech in progress

    @Test("Speech in progress is offered for a provisional translation")
    func pendingIsOffered() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.offerPending("How are you doing")
        #expect(pipeline.takeNext() == .pending("How are you doing"))
    }

    @Test("Settled sentences go before speech in progress")
    func settledFirst() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.offerPending("How are you doing")
        pipeline.settle(entry(0))
        #expect(pipeline.takeNext() == .entry(entry(0)))
        pipeline.finishCurrent()
        #expect(pipeline.takeNext() == .pending("How are you doing"))
    }

    @Test("The same speech in progress is not translated twice")
    func pendingNotRepeated() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.offerPending("How are you doing")
        _ = pipeline.takeNext()
        pipeline.finishCurrent()
        pipeline.offerPending("How are you doing")
        #expect(pipeline.takeNext() == nil)
    }

    @Test("Speech in progress is translated again only after it has grown noticeably")
    func pendingNeedsGrowth() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.offerPending("How are you")
        _ = pipeline.takeNext()
        pipeline.finishCurrent()
        pipeline.offerPending("How are you d")
        #expect(pipeline.takeNext() == nil)
        pipeline.offerPending("How are you doing")
        #expect(pipeline.takeNext() == .pending("How are you doing"))
    }

    @Test("A new clause is translated even if it is no longer than the last one")
    func newClauseIsTranslated() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.offerPending("How are you doing")
        _ = pipeline.takeNext()
        pipeline.finishCurrent()
        pipeline.offerPending("Fine thanks")
        #expect(pipeline.takeNext() == .pending("Fine thanks"))
    }

    @Test("A fragment too short to mean anything is not translated")
    func shortPendingIsSkipped() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.offerPending("Ho")
        #expect(pipeline.takeNext() == nil)
        pipeline.offerPending("はい")
        #expect(pipeline.takeNext() == .pending("はい"))
    }

    @Test("Speech in progress waits its turn like everything else")
    func pendingWaitsItsTurn() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.settle(entry(0))
        _ = pipeline.takeNext()
        pipeline.offerPending("How are you doing")
        #expect(pipeline.takeNext() == nil)
    }

    @Test("Resetting forgets everything and waits for a translator again")
    func reset() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.settle(entry(0))
        _ = pipeline.takeNext()
        pipeline.reset()
        #expect(pipeline.readiness == .preparing)
        pipeline.setReadiness(.ready)
        #expect(pipeline.takeNext() == nil)
        pipeline.settle(entry(1))
        #expect(pipeline.takeNext() == .entry(entry(1)))
    }
}

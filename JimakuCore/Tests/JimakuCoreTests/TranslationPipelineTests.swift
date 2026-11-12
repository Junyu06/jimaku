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
        #expect(pipeline.takeNext()?.id == 0)
    }

    @Test("Only one sentence is translated at a time, in order")
    func oneAtATime() {
        var pipeline = TranslationPipeline()
        pipeline.setReadiness(.ready)
        pipeline.settle(entry(0))
        pipeline.settle(entry(1))
        #expect(pipeline.takeNext()?.id == 0)
        #expect(pipeline.takeNext() == nil)
        pipeline.finishCurrent()
        #expect(pipeline.takeNext()?.id == 1)
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
        #expect(pipeline.takeNext()?.id == 1)
        pipeline.finishCurrent()
        #expect(pipeline.takeNext()?.id == 2)
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
        #expect(pipeline.takeNext()?.id == 1)
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
        #expect(pipeline.takeNext()?.id == 1)
    }
}

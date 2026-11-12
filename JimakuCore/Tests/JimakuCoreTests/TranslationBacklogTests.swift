import JimakuCore
import Testing

@Suite("TranslationBacklog")
struct TranslationBacklogTests {
    private func entry(_ id: Int) -> Transcript.Entry {
        Transcript.Entry(id: id, original: "sentence \(id)", translation: nil)
    }

    @Test("An empty backlog has nothing to translate")
    func emptyHasNothing() {
        var backlog = TranslationBacklog(limit: 3)
        #expect(backlog.isEmpty)
        #expect(backlog.next() == nil)
    }

    @Test("Entries come out in the order they went in")
    func firstInFirstOut() {
        var backlog = TranslationBacklog(limit: 3)
        backlog.add(entry(0))
        backlog.add(entry(1))
        #expect(backlog.next()?.id == 0)
        #expect(backlog.next()?.id == 1)
        #expect(backlog.next() == nil)
        #expect(backlog.isEmpty)
    }

    @Test("When translation falls behind, the oldest waiting entries are dropped")
    func overflowDropsOldest() {
        var backlog = TranslationBacklog(limit: 2)
        let dropped0 = backlog.add(entry(0))
        let dropped1 = backlog.add(entry(1))
        let dropped2 = backlog.add(entry(2))
        #expect(dropped0.isEmpty)
        #expect(dropped1.isEmpty)
        #expect(dropped2.map(\.id) == [0])
        #expect(backlog.next()?.id == 1)
        #expect(backlog.next()?.id == 2)
    }

    @Test("Taking an entry makes room for another")
    func takingMakesRoom() {
        var backlog = TranslationBacklog(limit: 2)
        backlog.add(entry(0))
        backlog.add(entry(1))
        _ = backlog.next()
        #expect(backlog.add(entry(2)).isEmpty)
        #expect(backlog.next()?.id == 1)
        #expect(backlog.next()?.id == 2)
    }

    @Test("Clearing removes everything that was waiting")
    func clear() {
        var backlog = TranslationBacklog(limit: 3)
        backlog.add(entry(0))
        backlog.removeAll()
        #expect(backlog.isEmpty)
        #expect(backlog.next() == nil)
    }
}

@Suite("TargetLanguage")
struct TargetLanguageTests {
    @Test("Captions are translated into Simplified Chinese")
    func simplifiedChinese() {
        #expect(TargetLanguage.identifier == "zh-Hans")
    }
}

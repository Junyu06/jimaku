import JimakuCore
import Testing

@Suite("CaptionLines")
struct CaptionLinesTests {
    @Test("Both lines present: original on top as secondary, translation below as primary")
    func bothLines() {
        let lines = CaptionLines(original: "Hello", translation: "你好")
        #expect(lines.rows == [
            CaptionRow(text: "Hello", role: .secondary),
            CaptionRow(text: "你好", role: .primary),
        ])
    }

    @Test("Only the original present: it becomes the primary row")
    func originalOnly() {
        let lines = CaptionLines(original: "Hello", translation: "")
        #expect(lines.rows == [CaptionRow(text: "Hello", role: .primary)])
    }

    @Test("Only the translation present: it is the primary row")
    func translationOnly() {
        let lines = CaptionLines(original: "", translation: "你好")
        #expect(lines.rows == [CaptionRow(text: "你好", role: .primary)])
    }

    @Test("Nothing present: no rows")
    func empty() {
        #expect(CaptionLines(original: "", translation: "").rows.isEmpty)
    }

    @Test("Whitespace-only text counts as absent")
    func whitespaceIsAbsent() {
        let lines = CaptionLines(original: "  \n", translation: "你好")
        #expect(lines.rows == [CaptionRow(text: "你好", role: .primary)])
    }
}

@Suite("DemoCaptions")
struct DemoCaptionsTests {
    @Test("Every demo entry has both an original and a translation")
    func entriesAreComplete() {
        #expect(!DemoCaptions.script.isEmpty)
        for lines in DemoCaptions.script {
            #expect(lines.rows.count == 2)
        }
    }

    @Test("Tick 0 shows the first entry")
    func firstTick() {
        #expect(DemoCaptions.lines(at: 0) == DemoCaptions.script[0])
    }

    @Test("Consecutive ticks show different captions")
    func consecutiveTicksDiffer() {
        #expect(DemoCaptions.script.count >= 2)
        for tick in 0..<(DemoCaptions.script.count * 2) {
            #expect(DemoCaptions.lines(at: tick) != DemoCaptions.lines(at: tick + 1))
        }
    }

    @Test("Ticks wrap around the script")
    func wrapsAround() {
        let count = DemoCaptions.script.count
        #expect(DemoCaptions.lines(at: count) == DemoCaptions.script[0])
        #expect(DemoCaptions.lines(at: count * 3 + 1) == DemoCaptions.script[1])
    }

    @Test("A negative tick is treated as tick 0")
    func negativeTick() {
        #expect(DemoCaptions.lines(at: -5) == DemoCaptions.script[0])
    }
}

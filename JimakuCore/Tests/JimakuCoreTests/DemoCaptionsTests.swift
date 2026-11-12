import JimakuCore
import Testing

@Suite("DemoCaptions")
struct DemoCaptionsTests {
    @Test("Every demo entry has both an original and a translation")
    func entriesAreComplete() {
        #expect(!DemoCaptions.script.isEmpty)
        for lines in DemoCaptions.script {
            #expect(!lines.original.isEmpty)
            #expect(!lines.translation.isEmpty)
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

@Suite("Demo speech")
struct DemoSpeechTests {
    @Test("Each language has a few sentences, each with a translation")
    func speeches() {
        for language in SourceLanguage.allCases {
            let speech = DemoCaptions.speech(in: language)
            #expect(speech.count >= 4)
            for sentence in speech {
                #expect(!sentence.original.isEmpty)
                #expect(!sentence.translation.isEmpty)
            }
        }
    }

    private let speech = [
        CaptionLines(original: "One two three four.", translation: "一二三四。"),
        CaptionLines(original: "Five six.", translation: "五六。"),
    ]

    @Test("A whole sentence gets its whole translation")
    func wholeSentence() {
        #expect(DemoCaptions.translation(of: "Five six.", in: speech) == "五六。")
    }

    @Test("Part of a sentence gets the matching share of its translation")
    func partOfASentence() {
        #expect(DemoCaptions.translation(of: "One two", in: speech) == "一二")
        #expect(DemoCaptions.translation(of: "three four", in: speech) == "三四。")
    }

    @Test("Punctuation and capitals in the piece do not matter")
    func loosely() {
        #expect(DemoCaptions.translation(of: "one, TWO", in: speech) == "一二")
    }

    @Test("A piece that runs across sentences gets a share of each")
    func acrossSentences() {
        #expect(DemoCaptions.translation(of: "three four five six", in: speech) == "三四。五六。")
    }

    @Test("Text that is not in the speech has no translation")
    func unknown() {
        #expect(DemoCaptions.translation(of: "seven", in: speech) == nil)
        #expect(DemoCaptions.translation(of: "…", in: speech) == nil)
    }
}

import JimakuCore
import Testing

@Suite("CaptionLayout")
struct CaptionLayoutTests {
    @Test("By default the original gets one small line above two lines of translation")
    func defaults() {
        let layout = CaptionLayout(style: CaptionStyle())
        #expect(layout.original == CaptionLayout.Row(columns: 52, lines: 1, role: .secondary))
        #expect(layout.translation == CaptionLayout.Row(columns: 30, lines: 2, role: .primary))
    }

    @Test("A larger text size means fewer columns on a line")
    func textSizes() {
        let columns = CaptionStyle.TextSize.allCases.map {
            CaptionLayout(style: CaptionStyle(textSize: $0)).translation?.columns ?? 0
        }
        #expect(columns == [40, 30, 24])
        let original = CaptionStyle.TextSize.allCases.map {
            CaptionLayout(style: CaptionStyle(textSize: $0)).original?.columns ?? 0
        }
        #expect(original == [64, 52, 46])
    }

    @Test("Rows start with estimated widths and can be given measured ones")
    func measuredWidths() {
        var layout = CaptionLayout(style: CaptionStyle())
        #expect(layout.translation?.widths == .estimated)
        #expect(layout.original?.widths == .estimated)
        let bold = GlyphWidths(narrow: ["W": 1.9])
        layout.translation?.widths = bold
        #expect(layout.translation?.widths == bold)
        #expect(layout != CaptionLayout(style: CaptionStyle()))
    }

    @Test("Translation-only mode has no original row")
    func translationOnly() {
        let layout = CaptionLayout(style: CaptionStyle(mode: .translationOnly))
        #expect(layout.original == nil)
        #expect(layout.translation == CaptionLayout.Row(columns: 30, lines: 2, role: .primary))
    }

    @Test("The translation gets as many lines as the style asks for, and the original keeps one")
    func chosenLines() {
        for lines in [2, 3, 4, 5] {
            for size in CaptionStyle.TextSize.allCases {
                let layout = CaptionLayout(style: CaptionStyle(textSize: size, lines: lines))
                #expect(layout.translation?.lines == lines)
                #expect(layout.original?.lines == 1)
            }
        }
    }

    @Test("Alone, the translation has the lines the style asks for, at the small size as well")
    func chosenLinesAlone() {
        #expect(CaptionLayout(style: CaptionStyle(textSize: .small, mode: .translationOnly)).translation?.lines == 2)
        #expect(
            CaptionLayout(style: CaptionStyle(textSize: .small, mode: .translationOnly, lines: 4)).translation?.lines
                == 4)
    }

    @Test("When translation cannot run, the original gets the lines the style asks for")
    func chosenLinesWithoutTranslation() {
        let layout = CaptionLayout(style: CaptionStyle(lines: 3), translationAvailable: false)
        #expect(layout.original == CaptionLayout.Row(columns: 30, lines: 3, role: .primary))
    }

    @Test("A style has two to five lines, two unless told otherwise")
    func linesOfAStyle() {
        #expect(CaptionStyle().lines == 2)
        #expect(CaptionStyle.lineChoices == [2, 3, 4, 5])
        #expect(CaptionStyle(lines: 1).lines == 2)
        #expect(CaptionStyle(lines: 9).lines == 5)
        var style = CaptionStyle()
        style.lines = 7
        #expect(style.lines == 5)
    }

    @Test("When translation cannot run, the original takes the main row in either mode")
    func withoutTranslation() {
        for mode in CaptionStyle.Mode.allCases {
            let layout = CaptionLayout(style: CaptionStyle(mode: mode), translationAvailable: false)
            #expect(layout.translation == nil)
            #expect(layout.original == CaptionLayout.Row(columns: 30, lines: 2, role: .primary))
        }
    }
}

@Suite("CaptionBoard")
struct CaptionBoardTests {
    private let layout = CaptionLayout(
        original: CaptionLayout.Row(columns: 20, lines: 1, role: .secondary),
        translation: CaptionLayout.Row(columns: 12, lines: 2, role: .primary)
    )

    private func said(_ sentences: [(String, String?)], pending: String = "") -> Transcript {
        var transcript = Transcript(rules: .english)
        let entries = transcript.apply(.final(sentences.map(\.0).joined(separator: " ")), at: 0)
        for (entry, sentence) in zip(entries, sentences) {
            if let translation = sentence.1 { transcript.setTranslation(translation, for: entry.id) }
        }
        if !pending.isEmpty { transcript.apply(.partial(pending), at: 1) }
        return transcript
    }

    private func texts(_ row: CaptionRow?) -> [String] { row?.lines.map(\.text) ?? [] }

    @Test("A new board is empty but keeps its rows")
    func empty() {
        let board = CaptionBoard(layout: layout)
        #expect(board.isEmpty)
        #expect(board.rows.map(\.role) == [.secondary, .primary])
        #expect(board.rows.map(\.columns) == [20, 12])
        #expect(board.rows.map(\.lineCount) == [1, 2])
    }

    @Test("Kept speech is settled text, and stays until the next speech begins")
    func originalRow() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello.", nil)]))
        #expect(board.rows[0].lines == [CaptionLine(settled: "Hello.")])
        #expect(!board.isEmpty)
    }

    @Test("The speech in progress is tentative text on a line of its own")
    func speechInProgress() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello.", nil)], pending: "How are"))
        // The original row has one line, so the new speech takes it.
        #expect(board.rows[0].lines == [CaptionLine(settled: "", tentative: "How are")])
    }

    @Test("Each sentence starts on a new line, on both rows")
    func sentencesApart() {
        let roomy = CaptionLayout(
            original: CaptionLayout.Row(columns: 20, lines: 2, role: .secondary),
            translation: CaptionLayout.Row(columns: 12, lines: 2, role: .primary)
        )
        var board = CaptionBoard(layout: roomy)
        board.show(said([("Hello.", "你好。"), ("Bye.", "再见。")]))
        #expect(texts(board.rows[0]) == ["Hello.", "Bye."])
        #expect(texts(board.rows[1]) == ["你好。", "再见。"])
    }

    @Test("A translation longer than its row is shown from its beginning, then the rest")
    func longTranslationPages() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello.", "你好。"), ("How are you today?", "你今天过得怎么样？我很想知道。")]))
        #expect(texts(board.rows[1]) == ["你今天过得怎", "么样？我很想"])
        #expect(board.hasMore)
        board.showMore()
        #expect(texts(board.rows[1]) == ["么样？我很想", "知道。"])
        #expect(!board.hasMore)
    }

    @Test("The page counts up with each new translation and each turn, not with speech in progress")
    func pageCount() {
        var transcript = said([("Hello.", "你好。")])
        var board = CaptionBoard(layout: layout)
        board.show(transcript)
        let first = board.page
        transcript.apply(.partial("How are"), at: 1)
        board.show(transcript)
        board.show(transcript)
        #expect(board.page == first)
        for kept in transcript.apply(.final("How are you today?"), at: 2) {
            transcript.setTranslation("你今天过得怎么样？我很想知道。", for: kept.id)
        }
        board.show(transcript)
        #expect(board.page == first + 1)
        board.showMore()
        #expect(board.page == first + 2)
        // Nothing more to show: the page stays.
        board.showMore()
        #expect(board.page == first + 2)
    }

    @Test("A long translation whose first lines look like what was shown before is still a new page")
    func samePictureNewPage() {
        let only = CaptionLayout(original: nil, translation: CaptionLayout.Row(columns: 12, lines: 2, role: .primary))
        var transcript = said([("One.", "一二三四五六七八九十甲乙")])
        var board = CaptionBoard(layout: only)
        board.show(transcript)
        let rows = board.rows
        let page = board.page
        for kept in transcript.apply(.final("Two."), at: 1) {
            transcript.setTranslation("一二三四五六七八九十甲乙丙", for: kept.id)
        }
        board.show(transcript)
        #expect(board.rows == rows)
        #expect(board.page == page + 1)
        #expect(board.hasMore)
    }

    @Test("Laying the captions out again starts a new page")
    func relayStartsAPage() {
        let transcript = said([("Hello.", "你好。")])
        var board = CaptionBoard(layout: layout)
        board.show(transcript)
        let page = board.page
        board.relay(CaptionLayout(original: nil, translation: CaptionLayout.Row(columns: 30, lines: 3, role: .primary)), showing: transcript)
        #expect(board.page > page)
    }

    @Test("The original row does not page: of long speech it shows the end")
    func originalRowShowsTheEnd() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello there my friend, how are you today?", nil)]))
        #expect(texts(board.rows[0]) == ["today?"])
        #expect(!board.hasMore)
    }

    @Test("A sentence that needs every line of its row is shown alone")
    func longSentenceAlone() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello.", "你好。"), ("How are you today?", "你今天过得怎么样？")]))
        #expect(texts(board.rows[1]) == ["你今天过得怎", "么样？"])
    }

    @Test("Translations are settled text, and nothing else is shown as translation")
    func translationRow() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello.", "你好。")]))
        #expect(board.rows[1].lines == [CaptionLine(settled: "你好。")])
    }

    @Test("While speech waits to be translated, the translation row ends with a waiting mark")
    func waitingMark() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello.", "你好。")], pending: "How are"))
        #expect(board.rows[1].lines == [CaptionLine(settled: "你好。", tentative: "…")])

        var untranslated = CaptionBoard(layout: layout)
        untranslated.show(said([("Hello.", nil)]), translating: true)
        #expect(untranslated.rows[1].lines == [CaptionLine(settled: "", tentative: "…")])
    }

    @Test("An entry nobody is translating any more does not keep the waiting mark up")
    func abandonedEntryDoesNotWait() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello.", nil)]), translating: false)
        #expect(board.rows[1].lines.isEmpty)
    }

    @Test("The waiting mark goes away when nothing is waiting")
    func waitingMarkGoesAway() {
        var transcript = said([("Hello.", nil)])
        var board = CaptionBoard(layout: layout)
        board.show(transcript, translating: true)
        transcript.setTranslation("你好。", for: 0)
        board.show(transcript, translating: false)
        #expect(board.rows[1].lines == [CaptionLine(settled: "你好。")])
    }

    @Test("The waiting mark never takes a line of its own")
    func waitingMarkDoesNotRoll() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("One.", "一二三四五六"), ("Two.", "七八九十甲乙")], pending: "Three"))
        #expect(board.rows[1].lines == [CaptionLine(settled: "一二三四五六"), CaptionLine(settled: "七八九十甲乙")])
    }

    @Test("An entry that was overtaken does not keep the waiting mark up")
    func overtakenEntryDoesNotWait() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("One.", nil), ("Two.", "二。")]))
        #expect(board.rows[1].lines == [CaptionLine(settled: "二。")])
    }

    @Test("Showing the same transcript twice adds nothing")
    func showingTwice() {
        let transcript = said([("Hello.", "你好。")])
        var board = CaptionBoard(layout: layout)
        board.show(transcript)
        board.show(transcript)
        #expect(texts(board.rows[1]) == ["你好。"])
        #expect(texts(board.rows[0]) == ["Hello."])
    }

    @Test("A translation that arrives later is added when it arrives")
    func laterTranslation() {
        var transcript = said([("Hello.", nil)])
        var board = CaptionBoard(layout: layout)
        board.show(transcript, translating: true)
        #expect(board.rows[1].lines == [CaptionLine(settled: "", tentative: "…")])
        transcript.setTranslation("你好。", for: 0)
        board.show(transcript)
        #expect(texts(board.rows[1]) == ["你好。"])
    }

    @Test("An entry overtaken by a later translation is left out rather than put in the middle")
    func overtakenEntry() {
        var transcript = said([("One.", nil), ("Two.", "二。")])
        var board = CaptionBoard(layout: layout)
        board.show(transcript)
        #expect(texts(board.rows[1]) == ["二。"])
        transcript.setTranslation("一。", for: 0)
        board.show(transcript)
        #expect(texts(board.rows[1]) == ["二。"])
    }

    @Test("Rows roll on their own when they are full")
    func rolling() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello there my friend.", "你好我的朋友。"), ("How are you today?", "你今天过得怎么样？")]))
        #expect(texts(board.rows[0]) == ["How are you today?"])
        #expect(texts(board.rows[1]) == ["你今天过得怎", "么样？"])
    }

    @Test("The board breaks lines by the widths its layout carries")
    func boardUsesMeasuredWidths() {
        let widths = GlyphWidths(narrow: ["W": 1.9, " ": 0.4])
        let measured = CaptionLayout(
            original: CaptionLayout.Row(columns: 14, lines: 2, role: .secondary, widths: widths),
            translation: nil
        )
        var transcript = Transcript(rules: .english)
        transcript.apply(.final("WWWWWW WWWWWW"), at: 0)
        var board = CaptionBoard(layout: measured)
        board.show(transcript)
        #expect(texts(board.rows[0]) == ["WWWWWW", "WWWWWW"])
    }

    @Test("Changing the layout lays the recent captions out again")
    func relayout() {
        let transcript = said([("Hello.", "你好。"), ("How are you?", "你好吗？")], pending: "Fine")
        var board = CaptionBoard(layout: layout)
        board.show(transcript)
        let wide = CaptionLayout(
            original: nil,
            translation: CaptionLayout.Row(columns: 30, lines: 3, role: .primary)
        )
        board.relay(wide, showing: transcript)
        #expect(board.rows.map(\.role) == [.primary])
        // "Fine" is still waiting to be translated.
        let expected = [CaptionLine(settled: "你好。"), CaptionLine(settled: "你好吗？", tentative: "…")]
        #expect(board.rows[0].lines == expected)
        // Nothing is added twice afterwards.
        board.show(transcript)
        #expect(board.rows[0].lines == expected)
    }

    @Test("With more lines the row shows more of the recent sentences, and with fewer again only the newest")
    func moreAndFewerLines() {
        let transcript = said([("One.", "一。"), ("Two.", "二。"), ("Three.", "三。"), ("Four.", "四。")])
        var board = CaptionBoard(layout: CaptionLayout(style: CaptionStyle()))
        board.show(transcript)
        #expect(texts(board.rows[1]) == ["三。", "四。"])
        board.relay(CaptionLayout(style: CaptionStyle(lines: 4)), showing: transcript)
        #expect(texts(board.rows[1]) == ["一。", "二。", "三。", "四。"])
        #expect(!board.hasMore)
        board.relay(CaptionLayout(style: CaptionStyle(lines: 2)), showing: transcript)
        #expect(texts(board.rows[1]) == ["三。", "四。"])
        #expect(!board.hasMore)
    }

    @Test("A translation too long for two lines needs no second page with four, and needs one again with two")
    func longTranslationAcrossLineCounts() {
        // Three lines of twelve wide characters at the large size.
        let long = String(repeating: "甲", count: 30)
        let transcript = said([("Long.", long)])
        var board = CaptionBoard(layout: CaptionLayout(style: CaptionStyle(textSize: .large)))
        board.show(transcript)
        #expect(board.hasMore)
        var page = board.page
        board.relay(CaptionLayout(style: CaptionStyle(textSize: .large, lines: 4)), showing: transcript)
        #expect(texts(board.rows[1]).joined() == long)
        #expect(!board.hasMore)
        #expect(board.page > page)
        page = board.page
        board.relay(CaptionLayout(style: CaptionStyle(textSize: .large, lines: 2)), showing: transcript)
        #expect(texts(board.rows[1]).joined() == String(long.prefix(24)))
        #expect(board.hasMore)
        #expect(board.page > page)
    }

    @Test("A board with only the original row shows it as the main row")
    func originalOnly() {
        let alone = CaptionLayout(original: CaptionLayout.Row(columns: 24, lines: 2, role: .primary), translation: nil)
        var board = CaptionBoard(layout: alone)
        board.show(said([("Hello.", "你好。")]))
        #expect(board.rows.map(\.role) == [.primary])
        #expect(texts(board.rows[0]) == ["Hello."])
    }

    @Test("A caption pair can be laid out on its own, for the preview")
    func preview() {
        let rows = CaptionBoard.rows(for: CaptionLines(original: "Hello.", translation: "你好。"), layout: layout)
        #expect(rows.map(\.role) == [.secondary, .primary])
        #expect(rows[0].lines == [CaptionLine(settled: "Hello.", tentative: "")])
        #expect(rows[1].lines == [CaptionLine(settled: "你好。", tentative: "")])
    }
}

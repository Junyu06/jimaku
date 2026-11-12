import JimakuCore
import Testing

@Suite("CaptionLayout")
struct CaptionLayoutTests {
    @Test("By default the original gets one small line above two lines of translation")
    func defaults() {
        let layout = CaptionLayout(style: CaptionStyle())
        #expect(layout.original == CaptionLayout.Row(columns: 46, lines: 1, role: .secondary))
        #expect(layout.translation == CaptionLayout.Row(columns: 24, lines: 2, role: .primary))
    }

    @Test("A larger text size means fewer columns on a line")
    func textSizes() {
        let columns = CaptionStyle.TextSize.allCases.map {
            CaptionLayout(style: CaptionStyle(textSize: $0)).translation?.columns ?? 0
        }
        #expect(columns == [30, 24, 22])
        let original = CaptionStyle.TextSize.allCases.map {
            CaptionLayout(style: CaptionStyle(textSize: $0)).original?.columns ?? 0
        }
        #expect(original == [52, 46, 42])
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
        #expect(layout.translation == CaptionLayout.Row(columns: 24, lines: 2, role: .primary))
    }

    @Test("Small text leaves room for a third line of translation when it is alone")
    func smallTranslationOnly() {
        let layout = CaptionLayout(style: CaptionStyle(textSize: .small, mode: .translationOnly))
        #expect(layout.translation?.lines == 3)
    }

    @Test("When translation cannot run, the original takes the main row in either mode")
    func withoutTranslation() {
        for mode in CaptionStyle.Mode.allCases {
            let layout = CaptionLayout(style: CaptionStyle(mode: mode), translationAvailable: false)
            #expect(layout.translation == nil)
            #expect(layout.original == CaptionLayout.Row(columns: 24, lines: 2, role: .primary))
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

    @Test("Kept speech is settled text; the speech in progress follows as tentative")
    func originalRow() {
        var board = CaptionBoard(layout: layout)
        board.show(said([("Hello.", nil)], pending: "How are"))
        #expect(board.rows[0].lines == [CaptionLine(settled: "Hello.", tentative: " How are")])
        #expect(!board.isEmpty)
    }

    @Test("Translations are settled text; the provisional translation follows as tentative")
    func translationRow() {
        var transcript = said([("Hello.", "你好。")], pending: "How are")
        transcript.setPendingTranslation("你怎么", at: transcript.pendingMark)
        var board = CaptionBoard(layout: layout)
        board.show(transcript)
        #expect(board.rows[1].lines == [CaptionLine(settled: "你好。", tentative: "你怎么")])
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
        board.show(transcript)
        #expect(texts(board.rows[1]).isEmpty)
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
        #expect(texts(board.rows[0]) == ["today?"])
        #expect(texts(board.rows[1]) == ["友。你今天过", "得怎么样？"])
    }

    @Test("A long provisional translation shows only its beginning")
    func longProvisional() {
        var transcript = said([("Hello.", "你好。")], pending: "How are you doing today my friend")
        transcript.setPendingTranslation("你今天过得怎么样啊我的朋友们好", at: transcript.pendingMark)
        var board = CaptionBoard(layout: layout)
        board.show(transcript)
        #expect(
            board.rows[1].lines == [
                CaptionLine(settled: "你好。", tentative: "你今天"),
                CaptionLine(settled: "", tentative: "过得怎"),
            ])
    }

    @Test("When a translation takes the place of its provisional one, the row does not roll")
    func settlingDoesNotRoll() {
        var transcript = Transcript(rules: .english)
        transcript.apply(.final("One two."), at: 0)
        transcript.setTranslation("一二三四五。", for: 0)
        transcript.apply(.partial("Three four five."), at: 1)
        transcript.setPendingTranslation("甲乙丙丁戊。", at: transcript.pendingMark)
        var board = CaptionBoard(layout: layout)
        board.show(transcript)
        #expect(texts(board.rows[1]) == ["一二三四五。", "甲乙丙丁戊。"])

        let kept = transcript.apply(.partial("Three four five. Six"), at: 2)
        board.show(transcript)
        transcript.setTranslation("甲乙丙丁戊。", for: kept[0].id)
        board.show(transcript)
        #expect(
            board.rows[1].lines == [CaptionLine(settled: "一二三四五。"), CaptionLine(settled: "甲乙丙丁戊。")]
        )
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
        #expect(texts(board.rows[0]) == ["你好。你好吗？"])
        // Nothing is added twice afterwards.
        board.show(transcript)
        #expect(texts(board.rows[0]) == ["你好。你好吗？"])
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

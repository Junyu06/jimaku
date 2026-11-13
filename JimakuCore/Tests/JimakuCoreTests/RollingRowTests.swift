import JimakuCore
import Testing

@Suite("RollingRow")
struct RollingRowTests {
    private func texts(_ row: RollingRow) -> [String] { row.visible.map(\.text) }

    @Test("An empty row shows nothing")
    func empty() {
        let row = RollingRow(columns: 10, lines: 2)
        #expect(row.visible.isEmpty)
    }

    @Test("Appended text is shown as settled")
    func appended() {
        var row = RollingRow(columns: 10, lines: 2)
        row.append("这是字幕")
        #expect(row.visible == [CaptionLine(settled: "这是字幕", tentative: "")])
    }

    @Test("Chinese pieces join without a space, English pieces with one")
    func joining() {
        var chinese = RollingRow(columns: 20, lines: 1)
        chinese.append("你好，")
        chinese.append("世界")
        #expect(texts(chinese) == ["你好，世界"])

        var english = RollingRow(columns: 20, lines: 1)
        english.append("hello")
        english.append("world")
        #expect(texts(english) == ["hello world"])
    }

    @Test("Text that does not fit continues on the next line")
    func secondLine() {
        var row = RollingRow(columns: 10, lines: 2)
        row.append("这是一条演示字幕")
        #expect(texts(row) == ["这是一条演", "示字幕"])
    }

    @Test("When the lines are full, the oldest line leaves and the others move up unchanged")
    func rolls() {
        var row = RollingRow(columns: 10, lines: 2)
        row.append("这是一条演示字幕")
        row.append("这个窗口应该")
        #expect(texts(row) == ["示字幕这个", "窗口应该"])
        row.append("一直浮在上面")
        #expect(texts(row) == ["窗口应该一", "直浮在上面"])
    }

    @Test("Text that is shown never moves sideways: a row either stays or moves up one line")
    func textNeverReflows() {
        var row = RollingRow(columns: 12, lines: 2)
        let pieces = ["今天天气好，", "去公园吧，", "你觉得呢？", "带上午饭吧，", "别忘了带伞。", "走吧，", "路上小心点。", "好的，", "一会儿见。"]
        for piece in pieces {
            let before = texts(row)
            row.append(piece)
            let after = texts(row)
            guard before.count == 2 else { continue }
            if after[0] == before[0] {
                // No roll: only the last line grew.
                #expect(after[1].hasPrefix(before[1]))
            } else {
                // Rolled by one: what was the last line is now the first.
                #expect(after[0].hasPrefix(before[1]))
            }
        }
        #expect(texts(row).count == 2)
    }

    @Test("Tentative text follows the settled text and is marked")
    func tentative() {
        var row = RollingRow(columns: 20, lines: 2)
        row.append("你好，")
        row.setTentative("世界")
        #expect(row.visible == [CaptionLine(settled: "你好，", tentative: "世界")])
    }

    @Test("Tentative text is replaced, not added to")
    func tentativeIsReplaced() {
        var row = RollingRow(columns: 20, lines: 2)
        row.append("你好，")
        row.setTentative("世界")
        row.setTentative("世界和平")
        #expect(row.visible == [CaptionLine(settled: "你好，", tentative: "世界和平")])
        row.setTentative("")
        #expect(row.visible == [CaptionLine(settled: "你好，", tentative: "")])
    }

    @Test("Settled text takes the place of the tentative text")
    func settledAfterTentative() {
        var row = RollingRow(columns: 20, lines: 2)
        row.append("你好，")
        row.setTentative("世界")
        row.append("世界！")
        #expect(row.visible == [CaptionLine(settled: "你好，世界！", tentative: "世界")])
        row.setTentative("")
        #expect(texts(row) == ["你好，世界！"])
    }

    @Test("Tentative text that spills over a line splits across lines")
    func tentativeSpills() {
        var row = RollingRow(columns: 10, lines: 2)
        row.append("这是一条")
        row.setTentative("演示字幕")
        #expect(
            row.visible == [
                CaptionLine(settled: "这是一条", tentative: "演"),
                CaptionLine(settled: "", tentative: "示字幕"),
            ])
    }

    @Test("Long tentative text rolls the row like settled text does")
    func tentativeRolls() {
        var row = RollingRow(columns: 10, lines: 2)
        row.append("这是一条演示字幕")
        row.setTentative("这个窗口应该一直")
        #expect(texts(row) == ["窗口应该一", "直"])
    }

    @Test("A row that rolled does not roll back when the tentative text gets shorter")
    func doesNotRollBack() {
        var row = RollingRow(columns: 10, lines: 2)
        row.append("这是一条演示字幕")
        row.setTentative("这个窗口应该一直")
        let rolled = texts(row)
        #expect(rolled.first == "窗口应该一")
        row.setTentative("这个窗口应该")
        #expect(texts(row) == ["窗口应该"])
    }

    @Test("A row never goes blank while it has text")
    func neverBlank() {
        var row = RollingRow(columns: 10, lines: 1)
        row.append("这是一条")
        row.setTentative("演示字幕")
        #expect(texts(row) == ["示字幕"])
        row.setTentative("")
        #expect(texts(row) == ["这是一条"])
    }

    @Test("A one-line row starts over when the line is full")
    func oneLine() {
        var row = RollingRow(columns: 10, lines: 1)
        row.append("这是一条演")
        #expect(texts(row) == ["这是一条演"])
        row.append("示")
        #expect(texts(row) == ["示"])
    }

    @Test("Settled text that takes the place of tentative text in one step does not roll the row")
    func settlingInOneStep() {
        var row = RollingRow(columns: 10, lines: 2)
        row.append("这是一条")
        row.setTentative("演示字幕这个")
        #expect(texts(row) == ["这是一条演", "示字幕这个"])
        row.update(appending: ["演示字幕这个"], tentative: "")
        #expect(row.visible == [CaptionLine(settled: "这是一条演"), CaptionLine(settled: "示字幕这个")])
    }

    @Test("A character on a full line stays there when a mark arrives after it")
    func marksDoNotPullCharactersDown() {
        var tentative = RollingRow(columns: 10, lines: 2)
        tentative.append("一二三四五")
        tentative.setTentative("，六")
        #expect(tentative.visible.first?.settled == "一二三四五")

        var settled = RollingRow(columns: 10, lines: 2)
        settled.append("一二三四五")
        settled.append("，六")
        #expect(texts(settled).first == "一二三四五")
    }

    @Test("A settled line that is shown keeps its text, whatever is added after it")
    func settledLinesKeepTheirText() {
        // Pieces that begin with a mark are the hard case: the mark must not pull
        // the character before it onto the next line.
        let pieces = ["今天天气好", "，去公园吧", "。你觉得呢", "？带上午饭", "，别忘了带伞", "。走吧", "，路上小心点", "。"]
        var row = RollingRow(columns: 10, lines: 3)
        /// Settled lines seen so far that had a line after them, so they are full.
        var full: [String] = []
        for piece in pieces {
            for step in 0..<2 {
                if step == 0 { row.setTentative(piece) } else { row.update(appending: [piece], tentative: "") }
                let settled = row.visible.map(\.settled)
                // Whatever full line is still shown is shown exactly as before.
                for (index, line) in settled.enumerated() where index < settled.count - 1 && !line.isEmpty {
                    if let known = full.first(where: { $0.hasPrefix(line) || line.hasPrefix($0) }) {
                        #expect(known == line)
                    }
                }
                if step == 1 {
                    full.append(contentsOf: settled.dropLast().filter { !$0.isEmpty && !full.contains($0) })
                }
            }
        }
    }

    @Test("A row can break lines by measured widths")
    func measuredRow() {
        let widths = GlyphWidths(narrow: ["W": 1.9, " ": 0.4])
        var row = RollingRow(columns: 14, lines: 2, widths: widths)
        row.append("WWWWWW WWWWWW")
        #expect(texts(row) == ["WWWWWW", "WWWWWW"])
    }

    @Test("Tentative text that may not wrap is left out when it does not fit on the line")
    func tentativeThatMayNotWrap() {
        var full = RollingRow(columns: 10, lines: 2, tentativeWraps: false)
        full.append("一二三四五")
        full.setTentative("…")
        #expect(full.visible == [CaptionLine(settled: "一二三四五")])

        var roomy = RollingRow(columns: 10, lines: 2, tentativeWraps: false)
        roomy.append("一二三")
        roomy.setTentative("…")
        #expect(roomy.visible == [CaptionLine(settled: "一二三", tentative: "…")])
    }

    @Test("Tentative text that may not wrap never rolls the row")
    func tentativeThatMayNotWrapDoesNotRoll() {
        var row = RollingRow(columns: 10, lines: 2, tentativeWraps: false)
        row.append("一二三四五六七八九十")
        row.setTentative("…")
        #expect(texts(row) == ["一二三四五", "六七八九十"])
    }

    @Test("An empty row shows tentative text that may not wrap")
    func tentativeOnAnEmptyRow() {
        var row = RollingRow(columns: 10, lines: 2, tentativeWraps: false)
        row.setTentative("…")
        #expect(row.visible == [CaptionLine(settled: "", tentative: "…")])
    }

    @Test("Blank text changes nothing")
    func blank() {
        var row = RollingRow(columns: 10, lines: 2)
        row.append("  ")
        row.setTentative(" ")
        #expect(row.visible.isEmpty)
    }

    // MARK: Texts kept apart

    @Test("A row that keeps texts apart starts each one on a new line")
    func textsApart() {
        var row = RollingRow(columns: 20, lines: 2, textsApart: true)
        row.append("一二三")
        row.append("四五六")
        #expect(texts(row) == ["一二三", "四五六"])
    }

    @Test("A row that keeps texts apart rolls a whole text off at a time")
    func textsApartRoll() {
        var row = RollingRow(columns: 20, lines: 2, textsApart: true)
        row.append("一二三")
        row.append("四五六")
        row.append("七八九")
        #expect(texts(row) == ["四五六", "七八九"])
    }

    @Test("A text longer than a line wraps, and the next one still starts a new line")
    func textsApartWrap() {
        var row = RollingRow(columns: 10, lines: 3, textsApart: true)
        row.append("一二三四五六七")
        row.append("八九")
        #expect(texts(row) == ["一二三四五", "六七", "八九"])
    }

    @Test("A text whose start no longer fits leaves the row whole")
    func textsApartLeaveWhole() {
        var row = RollingRow(columns: 10, lines: 2, textsApart: true)
        row.append("一二三四五六七")
        #expect(texts(row) == ["一二三四五", "六七"])
        row.append("八九")
        #expect(texts(row) == ["八九"])
        row.append("十")
        #expect(texts(row) == ["八九", "十"])
    }

    @Test("A text longer than the whole row shows its end")
    func textsApartTooLong() {
        var row = RollingRow(columns: 10, lines: 2, textsApart: true)
        row.append("一二三")
        row.append("一二三四五六七八九十甲乙丙")
        #expect(texts(row) == ["六七八九十", "甲乙丙"])
    }

    // MARK: Paging

    private func paged(columns: Int = 10, lines: Int) -> RollingRow {
        RollingRow(columns: columns, lines: lines, textsApart: true, pages: true, tentativeWraps: false)
    }

    @Test("A row that pages fills from the top, each text on a line of its own")
    func pageFills() {
        var row = paged(lines: 3)
        row.append("一")
        #expect(texts(row) == ["一"])
        row.append("二")
        row.append("三")
        #expect(texts(row) == ["一", "二", "三"])
        #expect(!row.hasMore)
    }

    @Test("When the page is full the next text starts a new page, and nothing of the old one stays")
    func pageTurns() {
        var row = paged(lines: 3)
        ["一", "二", "三"].forEach { row.append($0) }
        row.append("四")
        #expect(texts(row) == ["四"])
        #expect(!row.hasMore)
        row.append("五")
        #expect(texts(row) == ["四", "五"])
    }

    @Test("A text that does not fit in what is left of the page starts a new page whole")
    func textStartsANewPage() {
        var row = paged(lines: 3)
        row.append("一")
        row.append("一二三四五六七")
        #expect(texts(row) == ["一", "一二三四五", "六七"])
        row.append("甲乙丙丁戊己")
        #expect(texts(row) == ["甲乙丙丁戊", "己"])
        #expect(!row.hasMore)
    }

    @Test("Text on a page stays where it is while the page fills")
    func textStaysInPlace() {
        var row = paged(lines: 3)
        row.append("一")
        let first = row.visible[0]
        row.append("二")
        row.append("三")
        #expect(row.visible[0] == first)
    }

    @Test("A row that pages shows a text longer than a page from its beginning")
    func pagesFromTheBeginning() {
        var row = paged(lines: 2)
        row.append("一二三")
        row.append("一二三四五六七八九十甲乙丙")
        #expect(texts(row) == ["一二三四五", "六七八九十"])
        #expect(row.hasMore)
    }

    @Test("Showing more turns to the rest of the text, and then there is no more")
    func showMore() {
        var row = paged(lines: 2)
        row.append("一二三四五六七八九十甲乙丙")
        row.showMore()
        #expect(texts(row) == ["甲乙丙"])
        #expect(!row.hasMore)
        row.showMore()
        #expect(texts(row) == ["甲乙丙"])
    }

    @Test("A text of many lines is shown a page at a time, no line twice")
    func severalPages() {
        var row = paged(columns: 4, lines: 2)
        row.append("一二三四五六七八九十")
        #expect(texts(row) == ["一二", "三四"])
        row.showMore()
        #expect(texts(row) == ["五六", "七八"])
        #expect(row.hasMore)
        row.showMore()
        #expect(texts(row) == ["九十"])
        #expect(!row.hasMore)
    }

    @Test("The next text goes on the page where a long text ends, and that page is shown")
    func nextTextAfterALongOne() {
        var row = paged(lines: 2)
        row.append("一二三四五六七八九十甲乙丙")
        row.append("丁")
        #expect(texts(row) == ["甲乙丙", "丁"])
        #expect(!row.hasMore)
    }

    @Test("Of several texts added at once, the page on which the newest begins is shown")
    func severalTextsAtOnce() {
        var row = paged(lines: 2)
        row.update(appending: ["一", "二", "三"], tentative: "")
        #expect(texts(row) == ["三"])
        #expect(!row.hasMore)
    }

    @Test("A mark added while a page is shown does not turn the page")
    func markDoesNotTurnThePage() {
        var row = paged(lines: 2)
        row.append("一二三四五六七八九十甲乙丙")
        row.setTentative("…")
        #expect(texts(row) == ["一二三四五", "六七八九十"])
        row.showMore()
        #expect(row.visible.last == CaptionLine(settled: "甲乙丙", tentative: "…"))
    }

    @Test("A row that pages gives tentative text no line of its own, whatever it is told")
    func pagedRowKeepsTentativeTextOnTheLine() {
        var row = RollingRow(columns: 2, lines: 1, textsApart: true, pages: true)
        #expect(!row.tentativeWraps)
        row.append("甲乙丙")
        #expect(texts(row) == ["甲"])
        row.setTentative("丁")
        #expect(texts(row) == ["甲"])
        row.setTentative("")
        row.showMore()
        row.showMore()
        #expect(texts(row) == ["丙"])
        #expect(!row.hasMore)
    }

    @Test("A row that pages goes on for many pages")
    func manyPages() {
        var row = paged(lines: 3)
        for index in 0..<100 { row.append("第\(index)") }
        #expect(texts(row) == ["第99"])
        row.append("末")
        #expect(texts(row) == ["第99", "末"])
    }

    // MARK: Paging with texts that follow one another

    private func flowing(columns: Int = 10, lines: Int) -> RollingRow {
        RollingRow(columns: columns, lines: lines, pages: true, tentativeWraps: false)
    }

    @Test("Texts follow one another on a line with nothing between them, or a space between narrow letters")
    func textsRunOn() {
        var row = flowing(lines: 2)
        row.append("一。")
        row.append("二")
        #expect(texts(row) == ["一。二"])
        var narrow = flowing(columns: 20, lines: 2)
        narrow.append("Hi.")
        narrow.append("Bye.")
        #expect(texts(narrow) == ["Hi. Bye."])
    }

    @Test("A flowing text that fits in what is left of the page runs on from the line being filled")
    func flowingTextFits() {
        var row = flowing(lines: 2)
        row.append("一二")
        row.append("三四五六")
        #expect(texts(row) == ["一二三四五", "六"])
        #expect(!row.hasMore)
    }

    @Test("A flowing text that does not fit in what is left of the page starts a new page at the top")
    func flowingTextStartsANewPage() {
        var row = flowing(lines: 2)
        row.append("一二三四五六七")
        #expect(texts(row) == ["一二三四五", "六七"])
        row.append("甲乙丙丁")
        #expect(texts(row) == ["甲乙丙丁"])
        #expect(!row.hasMore)
        row.append("戊")
        #expect(texts(row) == ["甲乙丙丁戊"])
    }

    @Test("A flowing text longer than a page starts a page of its own and is shown a page at a time")
    func flowingLongText() {
        var row = flowing(lines: 2)
        row.append("一")
        row.append("一二三四五六七八九十甲乙丙")
        #expect(texts(row) == ["一二三四五", "六七八九十"])
        #expect(row.hasMore)
        row.showMore()
        #expect(texts(row) == ["甲乙丙"])
        row.append("丁")
        #expect(texts(row) == ["甲乙丙丁"])
        #expect(!row.hasMore)
    }

    @Test("A mark goes after the last flowing text when it fits on the line, and is left out when it does not")
    func flowingMark() {
        var row = flowing(lines: 2)
        row.append("一二")
        row.setTentative("…")
        #expect(row.visible == [CaptionLine(settled: "一二", tentative: "…")])
        row.append("三四五")
        #expect(texts(row) == ["一二三四五"])
        row.append("六")
        #expect(row.visible == [CaptionLine(settled: "一二三四五"), CaptionLine(settled: "六", tentative: "…")])
    }

    @Test("Several flowing texts added at once go where they would have gone one by one")
    func flowingTextsAtOnce() {
        var one = flowing(lines: 2)
        ["一二三", "四五六", "七八九", "十甲乙"].forEach { one.append($0) }
        var all = flowing(lines: 2)
        all.update(appending: ["一二三", "四五六", "七八九", "十甲乙"], tentative: "")
        #expect(texts(one) == ["十甲乙"])
        #expect(texts(all) == texts(one))
        #expect(!all.hasMore)
    }

    @Test("A mark on an empty page, taken back, leaves the page empty for the first text")
    func markBeforeAnyText() {
        var row = flowing(lines: 2)
        row.setTentative("…")
        #expect(row.visible == [CaptionLine(settled: "", tentative: "…")])
        row.setTentative("")
        #expect(row.visible.isEmpty)
        #expect(!row.hasMore)
        row.append("一")
        #expect(texts(row) == ["一"])
    }

    @Test("By measured widths, a text that just fits stays on the page and one that is just too wide turns it")
    func measuredWidthsDecideThePage() {
        let widths = GlyphWidths(narrow: ["a": 1.5, " ": 1])
        var row = RollingRow(columns: 4, lines: 1, pages: true, tentativeWraps: false, widths: widths)
        row.append("a")
        row.append("a")
        // 1.5 + 1 + 1.5 columns: exactly the line.
        #expect(texts(row) == ["a a"])
        #expect(!row.hasMore)
        row.append("a")
        #expect(texts(row) == ["a"])
        #expect(!row.hasMore)

        // A hair wider, and the second no longer fits: by estimate it would.
        let wider = GlyphWidths(narrow: ["a": 1.5 + 1.0 / 1024, " ": 1])
        var tight = RollingRow(columns: 4, lines: 1, pages: true, tentativeWraps: false, widths: wider)
        tight.append("a")
        tight.append("a")
        #expect(texts(tight) == ["a"])
    }

    @Test("Flowing pages turned, a mark taken back, text added, and pages turned again keep the row in step")
    func flowingPagesAndMarks() {
        var row = flowing(columns: 4, lines: 2)
        row.append("一二三四五六七八九十")
        row.setTentative("…")
        #expect(texts(row) == ["一二", "三四"])
        row.showMore()
        #expect(texts(row) == ["五六", "七八"])
        row.setTentative("")
        row.showMore()
        #expect(texts(row) == ["九十"])
        #expect(!row.hasMore)
        // What follows runs on where the long text ended.
        row.append("甲")
        #expect(texts(row) == ["九十", "甲"])
        // A short text arrives while a long one still has pages to show: the
        // page where the long one ends is shown, with the short one after it.
        row.append("乙丙丁戊己庚")
        #expect(texts(row) == ["乙丙", "丁戊"])
        #expect(row.hasMore)
        row.update(appending: ["辛"], tentative: "…")
        #expect(texts(row) == ["己庚", "辛…"])
        #expect(!row.hasMore)
    }

    @Test("Pages turned, text added, a mark taken back, and pages turned again keep the row in step")
    func pagesAndMarks() {
        var row = paged(columns: 4, lines: 2)
        row.append("一二三四五六七八九十")
        #expect(texts(row) == ["一二", "三四"])
        row.setTentative("…")
        #expect(texts(row) == ["一二", "三四"])
        row.showMore()
        #expect(texts(row) == ["五六", "七八"])
        row.setTentative("")
        #expect(texts(row) == ["五六", "七八"])
        row.showMore()
        #expect(texts(row) == ["九十"])
        #expect(!row.hasMore)
        // What follows goes on the page where the long text ended.
        row.append("甲")
        #expect(texts(row) == ["九十", "甲"])
        // A long text that does not fit there starts a page of its own.
        row.update(appending: ["乙丙丁戊己"], tentative: "…")
        #expect(texts(row) == ["乙丙", "丁戊"])
        #expect(row.hasMore)
        row.showMore()
        #expect(row.visible == [CaptionLine(settled: "己", tentative: "…")])
        #expect(!row.hasMore)
    }

    @Test("A row that does not page has nothing more to show")
    func noPaging() {
        var row = RollingRow(columns: 10, lines: 2, textsApart: true)
        row.append("一二三四五六七八九十甲乙丙")
        #expect(!row.hasMore)
        #expect(texts(row) == ["六七八九十", "甲乙丙"])
    }

    @Test("Speech that is kept shorter than it was guessed is shown from its beginning")
    func settledShorterThanTentative() {
        var row = RollingRow(columns: 10, lines: 2, textsApart: true)
        row.append("甲乙")
        row.setTentative("一二三四五六七八九十甲乙丙")
        #expect(texts(row) == ["六七八九十", "甲乙丙"])
        row.update(appending: ["一二三四五六七"], tentative: "")
        #expect(texts(row) == ["一二三四五", "六七"])
    }

    @Test("When new speech is withdrawn, the text before it comes back whole")
    func withdrawnSpeechBringsTheTextBack() {
        var row = RollingRow(columns: 10, lines: 2, textsApart: true)
        row.append("一二三四五六七")
        row.setTentative("八九")
        #expect(texts(row) == ["八九"])
        row.setTentative("")
        #expect(texts(row) == ["一二三四五", "六七"])
    }

    @Test("Tentative text that gets shorter is shown from its beginning again")
    func tentativeGetsShorter() {
        var row = RollingRow(columns: 10, lines: 2, textsApart: true)
        row.append("甲乙")
        row.setTentative("一二三四五六七八九十甲乙丙")
        row.setTentative("一二三四五六七")
        #expect(texts(row) == ["一二三四五", "六七"])
    }

    @Test("Tentative text that may wrap starts a new line after a text kept apart")
    func textsApartTentative() {
        var row = RollingRow(columns: 20, lines: 2, textsApart: true)
        row.append("一二三")
        row.setTentative("四五")
        #expect(row.visible == [CaptionLine(settled: "一二三"), CaptionLine(settled: "", tentative: "四五")])
        // It becomes settled text on the line it was on.
        row.update(appending: ["四五六"], tentative: "")
        #expect(texts(row) == ["一二三", "四五六"])
    }

    @Test("A mark that may not wrap stays at the end of the last text")
    func textsApartMark() {
        var row = RollingRow(columns: 20, lines: 2, textsApart: true, tentativeWraps: false)
        row.append("一二三")
        row.setTentative("…")
        #expect(row.visible == [CaptionLine(settled: "一二三", tentative: "…")])
    }

    @Test("On a row of one line, new speech takes the place of the text before it")
    func textsApartOneLine() {
        var row = RollingRow(columns: 20, lines: 1, textsApart: true)
        row.append("一二三")
        row.setTentative("四")
        #expect(row.visible == [CaptionLine(settled: "", tentative: "四")])
        // If the new speech is withdrawn, the text before it comes back.
        row.setTentative("")
        #expect(texts(row) == ["一二三"])
    }
}

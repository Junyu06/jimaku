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
}

import JimakuCore
import Testing

@Suite("CaptionText widths")
struct CaptionTextWidthTests {
    @Test("A wide character counts as two columns")
    func wideCharacters() {
        #expect(CaptionText.width(of: "abc") == 3)
        #expect(CaptionText.width(of: "字幕") == 4)
        #expect(CaptionText.width(of: "a字") == 3)
    }
}

@Suite("Spoken characters")
struct SpokenCharacterTests {
    @Test("Letters and digits are spoken; punctuation and spaces are not")
    func counting() {
        #expect(CaptionText.spokenCount(in: "こんにちは、世界。") == 7)
        #expect(CaptionText.spokenCount(in: "Hello, world! 42") == 12)
        #expect(CaptionText.spokenCount(in: " 、。…") == 0)
    }

    @Test("Dropping nothing leaves the text as it is")
    func droppingNothing() {
        #expect(CaptionText.dropping(spoken: 0, from: " 先生、こんにちは") == "先生、こんにちは")
    }

    @Test("Dropping spoken characters also drops the marks that close them")
    func droppingTakesClosingMarks() {
        #expect(CaptionText.dropping(spoken: 8, from: "説明してください。先生") == "先生")
        #expect(CaptionText.dropping(spoken: 5, from: "I said, look, I just") == "look, I just")
    }

    @Test("The same spoken characters are dropped whether or not the period is there")
    func punctuationDoesNotMatter() {
        #expect(CaptionText.dropping(spoken: 8, from: "説明してください先生") == "先生")
        #expect(CaptionText.dropping(spoken: 8, from: "説明して、ください。先生") == "先生")
    }

    @Test("A mark that opens what comes next is kept")
    func openingMarksStay() {
        #expect(CaptionText.dropping(spoken: 4, from: "そうです。「はい」と") == "「はい」と")
    }

    @Test("Dropping more than there is leaves nothing")
    func droppingEverything() {
        #expect(CaptionText.dropping(spoken: 9, from: "はい。") == "")
    }
}

@Suite("Cutting speech into pieces")
struct ChunkTests {
    private let japanese = ChunkRules(clauseMinimum: 12, limit: 36)
    private let english = ChunkRules(clauseMinimum: 20, limit: 60)

    private func cut(
        _ text: String,
        stable: Int? = nil,
        complete: Bool = false,
        rules: ChunkRules? = nil
    ) -> (chunks: [String], rest: String, spoken: Int) {
        CaptionText.chunks(
            in: text,
            stableSpoken: stable ?? CaptionText.spokenCount(in: text),
            isComplete: complete,
            rules: rules ?? japanese
        )
    }

    @Test("Nothing is cut from text that may still change")
    func nothingStable() {
        let result = cut("ゆっくり説明してください。先生サン", stable: 0)
        #expect(result.chunks.isEmpty)
        #expect(result.rest == "ゆっくり説明してください。先生サン")
        #expect(result.spoken == 0)
    }

    @Test("A finished sentence is cut once all of it is stable")
    func stableSentence() {
        let result = cut("ゆっくり説明してください。先生サン", stable: 12)
        #expect(result.chunks == ["ゆっくり説明してください。"])
        #expect(result.rest == "先生サン")
        #expect(result.spoken == 12)
    }

    @Test("A sentence whose end is not stable yet is left alone")
    func unstableSentence() {
        let result = cut("ゆっくり説明してください。先生サン", stable: 11)
        #expect(result.chunks.isEmpty)
    }

    @Test("Several finished sentences are cut one by one")
    func severalSentences() {
        let result = cut("はい。そうです。次は")
        #expect(result.chunks == ["はい。", "そうです。"])
        #expect(result.rest == "次は")
        #expect(result.spoken == 6)
    }

    @Test("A clause mark cuts when enough has been said before it")
    func clauseMark() {
        let result = cut("このお店もうすぐ閉まるって聞いたんだけど、本当なのかな")
        #expect(result.chunks == ["このお店もうすぐ閉まるって聞いたんだけど、"])
        #expect(result.rest == "本当なのかな")
        #expect(result.spoken == 20)
    }

    @Test("A clause mark after only a word or two does not cut")
    func earlyClauseMark() {
        let result = cut("はい、こちらになります")
        #expect(result.chunks.isEmpty)
        #expect(result.rest == "はい、こちらになります")
    }

    @Test("When the text is complete, its end is cut too")
    func completeText() {
        let result = cut("はい、こちらになります", complete: true)
        #expect(result.chunks == ["はい、こちらになります"])
        #expect(result.rest == "")
        #expect(result.spoken == 10)
    }

    @Test("Long Japanese speech without marks is cut where a new word starts")
    func longJapanese() {
        // 29 characters, no punctuation. The cut falls before a kanji that follows
        // hiragana, as late as the limit allows.
        let result = cut("今日行くの行かないのゆっくり説明してくださいと言われたので")
        #expect(result.chunks == ["今日行くの行かないのゆっくり"])
        #expect(result.rest == "説明してくださいと言われたので")
        #expect(result.spoken == 14)
    }

    @Test("Japanese is cut after a form that joins clauses when there is one")
    func japaneseJoiningForm() {
        // Words start after から, まで, に, and と; the first of them ends a clause.
        let result = cut("今日は天気がいいから公園まで散歩に行こうと思う")
        #expect(result.chunks == ["今日は天気がいいから"])
        #expect(result.rest == "公園まで散歩に行こうと思う")
    }

    @Test("A single し or て inside a word is not taken for the end of a clause")
    func shortFormsInsideWords() {
        // 出し入れ is one word; the cut goes to the last word start within the limit.
        let text = "今日は倉庫に置いた古い荷物を出し入れする道具について説明します"
        let result = cut(text, rules: .japanese)
        #expect(result.chunks == ["今日は倉庫に置いた古い荷物を出し入れする"])
        #expect(result.rest == "道具について説明します")
    }

    @Test("Speech shorter than the limit waits for more")
    func shortSpeechWaits() {
        let result = cut("今日行くの行かないのゆっくり")
        #expect(result.chunks.isEmpty)
    }

    @Test("Long English speech without marks is cut between words")
    func longEnglish() {
        let text = "the quick brown fox jumps over the lazy dog near the old river bank today again twice"
        let result = cut(text, rules: english)
        #expect(result.chunks == ["the quick brown fox jumps over the lazy dog near the old"])
        #expect(result.rest == "river bank today again twice")
    }

    @Test("It is cut before a joining word when there is one, so each piece is a clause")
    func englishJoiningWord() {
        let text = "so I walked into the store yesterday and the guy behind the counter looked at me like I was"
        let result = cut(text, rules: english)
        #expect(result.chunks == ["so I walked into the store yesterday"])
        #expect(result.rest == "and the guy behind the counter looked at me like I was")
    }

    @Test("A joining word right at the start does not cut")
    func earlyJoiningWord() {
        let text = "well and then the guy behind the counter looked at me like I was completely crazy"
        let result = cut(text, rules: english)
        #expect(result.chunks == ["well and then the guy behind the counter looked at me like I"])
    }

    @Test("A word with an apostrophe or a hyphen is never cut inside")
    func contractionsStayWhole() {
        // "it's" straddles the limit: its "s" would start at column 60.
        let text = "we kept walking along the river past the old wooden gate it's still open"
        let result = cut(text, rules: english)
        #expect(result.chunks == ["we kept walking along the river past the old wooden gate"])
        #expect(result.rest == "it's still open")

        let hyphenated = "we kept walking along the river past the old wooden well-known gate here"
        #expect(cut(hyphenated, rules: english).rest == "well-known gate here")
    }

    @Test("A period inside a number or after a title does not cut")
    func periodsThatDoNotEnd() {
        #expect(cut("It costs 3.5 dollars. Next", rules: english).chunks == ["It costs 3.5 dollars."])
        #expect(cut("Dr. Smith is here. Next", rules: english).chunks == ["Dr. Smith is here."])
        #expect(cut("Wait... maybe not. Next", rules: english).chunks == ["Wait... maybe not."])
    }

    @Test("A comma inside a number does not cut")
    func commaInNumber() {
        let result = cut("it was about 1,000 dollars in total", rules: english)
        #expect(result.chunks.isEmpty)
    }

    @Test("A comma cuts English once enough has been said")
    func englishComma() {
        let result = cut("He said that the meeting is off, so it is", rules: english)
        #expect(result.chunks == ["He said that the meeting is off,"])
        #expect(result.rest == "so it is")
    }

    @Test("Closing quotes and repeated marks stay with their sentence")
    func closersStay() {
        #expect(cut("本当ですか？！次").chunks == ["本当ですか？！"])
        #expect(cut("He said \"stop.\" Then", rules: english).chunks == ["He said \"stop.\""])
    }

    @Test("Marks alone make no piece")
    func marksAlone() {
        let result = cut("。、", complete: true)
        #expect(result.chunks.isEmpty)
        #expect(result.spoken == 0)
    }

    @Test("A sentence that is over stays whole, comma and all, where the same words still being said are cut")
    func finishedSentenceStaysWhole() {
        // 50 columns: past the limit of 48, within the 72 a finished sentence may have.
        let text = "昨日は雨が降っていたので、家で本を読んでいました。"
        #expect(cut(text, complete: true, rules: .japanese).chunks == [text])
        let unfinished = "昨日は雨が降っていたので、家で本を読んでいました"
        #expect(cut(unfinished, rules: .japanese).chunks == ["昨日は雨が降っていたので、"])
    }

    @Test("A sentence that is over but far too long is still cut at its comma")
    func finishedSentenceTooLong() {
        let text = "昨日は朝からずっと雨が降っていたので、図書館には行かずに家で古い小説をゆっくり読んでいました。"
        #expect(
            cut(text, complete: true, rules: .japanese).chunks
                == ["昨日は朝からずっと雨が降っていたので、", "図書館には行かずに家で古い小説をゆっくり読んでいました。"])
    }

    @Test("Finished sentences are still cut from one another")
    func finishedSentencesApart() {
        #expect(cut("はい。そうです。行きましょう", complete: true, rules: .japanese).chunks == ["はい。", "そうです。", "行きましょう"])
    }

    @Test("The room a finished sentence has is one and a half times the limit")
    func wholeAllowance() {
        #expect(ChunkRules.japanese.whole == 72)
        #expect(ChunkRules.english.whole == 108)
    }

    @Test("The pieces and the rest together are the text, with nothing lost or repeated")
    func nothingLost() {
        let text = "このお店もうすぐ閉まるって聞いたんだけど、本当なのかな今日行くの行かないのゆっくり説明してください。先生サンドイッチを見せてもらえますか"
        for stable in 0...CaptionText.spokenCount(in: text) {
            let result = cut(text, stable: stable)
            let rebuilt = (result.chunks + [result.rest]).joined()
            #expect(rebuilt == text)
            #expect(result.spoken == result.chunks.reduce(0) { $0 + CaptionText.spokenCount(in: $1) })
        }
    }
}

@Suite("Breaking text into lines")
struct WrapTests {
    @Test("Text that fits stays on one line")
    func fits() {
        #expect(CaptionText.wrap("这是字幕", columns: 10) == ["这是字幕"])
        #expect(CaptionText.wrap("", columns: 10) == [])
    }

    @Test("Chinese breaks wherever the line is full")
    func chinese() {
        #expect(CaptionText.wrap("这是一条演示字幕这是", columns: 10) == ["这是一条演", "示字幕这是"])
    }

    @Test("A mark that closes a phrase never starts a line")
    func marksDoNotStartLines() {
        #expect(CaptionText.wrap("这是一条演，示字幕", columns: 10) == ["这是一条", "演，示字幕"])
    }

    @Test("English breaks between words")
    func english() {
        #expect(CaptionText.wrap("the quick brown fox", columns: 10) == ["the quick", "brown fox"])
    }

    @Test("A word longer than a line is broken inside")
    func longWord() {
        #expect(CaptionText.wrap("abcdefghijklmnop", columns: 10) == ["abcdefghij", "klmnop"])
    }

    @Test("A mark does not start a line even after a word that had to be broken")
    func marksAfterLongWords() {
        #expect(CaptionText.wrap("abcdefghij,", columns: 10) == ["abcdefghi", "j,"])
    }

    @Test("Keeping a mark off the start of a line never makes a line too wide")
    func marksNeverWidenALine() {
        // The character before the mark is only taken along when both fit.
        #expect(CaptionText.wrap("(甲，", columns: 3) == ["(甲", "，"])
        #expect(CaptionText.wrap("aW，", columns: 4, widths: GlyphWidths(narrow: ["W": 3])) == ["aW", "，"])
    }

    @Test("A character wider than a whole line gets a line to itself")
    func widerThanALine() {
        #expect(CaptionText.wrap("aWb", columns: 4, widths: GlyphWidths(narrow: ["W": 9])) == ["a", "W", "b"])
    }

    @Test("With measured widths, wide letters take more room and thin ones less")
    func measuredWidths() {
        let widths = GlyphWidths(narrow: ["W": 1.9, "i": 0.5, "l": 0.5, " ": 0.4])
        // By estimate both fit in fourteen columns on one line.
        #expect(CaptionText.wrap("WWWWWW WWWWWW", columns: 14) == ["WWWWWW WWWWWW"])
        #expect(CaptionText.wrap("WWWWWW WWWWWW", columns: 14, widths: widths) == ["WWWWWW", "WWWWWW"])
        #expect(CaptionText.wrap("illi illi illi illi", columns: 14) == ["illi illi illi", "illi"])
        #expect(CaptionText.wrap("illi illi illi illi", columns: 14, widths: widths) == ["illi illi illi illi"])
    }

    @Test("A narrow character that was not measured gets the fallback width")
    func unmeasuredWidths() {
        let widths = GlyphWidths(narrow: ["a": 1], unknownNarrow: 2)
        #expect(widths.width(of: "a") == 1)
        #expect(widths.width(of: "é") == 2)
        #expect(widths.width(of: "字") == 2)
        #expect(GlyphWidths.estimated.width(of: "é") == 1)
    }

    @Test("English inside Chinese stays whole")
    func mixed() {
        #expect(CaptionText.wrap("切到别的 app，继续看。", columns: 12) == ["切到别的", "app，继续", "看。"])
        #expect(CaptionText.wrap("切到别的 app，继续看。", columns: 14) == ["切到别的 app，", "继续看。"])
    }
}

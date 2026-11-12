import JimakuCore
import Testing

@Suite("Transcript")
struct TranscriptTests {
    @Test("A new transcript has nothing to show")
    func newIsEmpty() {
        let transcript = Transcript()
        #expect(transcript.entries.isEmpty)
        #expect(transcript.pending.isEmpty)
        #expect(transcript.currentLines.rows.isEmpty)
    }

    @Test("A partial result is shown but not kept")
    func partialIsPending() {
        var transcript = Transcript()
        let finished = transcript.apply(.partial("Hello wor"))
        #expect(finished == nil)
        #expect(transcript.entries.isEmpty)
        #expect(transcript.currentLines.original == "Hello wor")
    }

    @Test("A later partial replaces the earlier one")
    func partialReplacesPartial() {
        var transcript = Transcript()
        transcript.apply(.partial("Hello wor"))
        transcript.apply(.partial("Hello world, how"))
        #expect(transcript.currentLines.original == "Hello world, how")
    }

    @Test("A final result becomes an entry and stays on screen")
    func finalBecomesEntry() {
        var transcript = Transcript()
        transcript.apply(.partial("Hello wor"))
        let finished = transcript.apply(.final(" Hello world. "))
        #expect(finished == Transcript.Entry(id: 0, original: "Hello world.", translation: nil))
        #expect(transcript.entries == [Transcript.Entry(id: 0, original: "Hello world.", translation: nil)])
        #expect(transcript.pending.isEmpty)
        #expect(transcript.currentLines.original == "Hello world.")
    }

    @Test("Entries are numbered in order")
    func entriesAreNumbered() {
        var transcript = Transcript()
        transcript.apply(.final("One."))
        let second = transcript.apply(.final("Two."))
        #expect(second?.id == 1)
        #expect(transcript.entries.map(\.original) == ["One.", "Two."])
    }

    @Test("An empty final result clears the partial and adds nothing")
    func emptyFinal() {
        var transcript = Transcript()
        transcript.apply(.final("One."))
        transcript.apply(.partial("uh"))
        let finished = transcript.apply(.final("  "))
        #expect(finished == nil)
        #expect(transcript.entries.count == 1)
        #expect(transcript.currentLines.original == "One.")
    }

    @Test("New speech replaces the previous sentence on the original row")
    func partialAfterFinal() {
        var transcript = Transcript()
        transcript.apply(.final("One."))
        transcript.apply(.partial("Two is"))
        #expect(transcript.currentLines.original == "Two is")
    }

    @Test("A translation is attached to its entry and shown")
    func translationIsShown() {
        var transcript = Transcript()
        transcript.apply(.final("Hello."))
        transcript.setTranslation("你好。", for: 0)
        #expect(transcript.entries[0].translation == "你好。")
        #expect(transcript.currentLines == CaptionLines(original: "Hello.", translation: "你好。"))
    }

    @Test("The latest translation stays up while the next sentence is being spoken")
    func translationStaysDuringNextPartial() {
        var transcript = Transcript()
        transcript.apply(.final("Hello."))
        transcript.setTranslation("你好。", for: 0)
        transcript.apply(.partial("How are"))
        #expect(transcript.currentLines == CaptionLines(original: "How are", translation: "你好。"))
    }

    @Test("The translation row shows the newest translated entry, whatever order translations arrive in")
    func newestTranslationWins() {
        var transcript = Transcript()
        transcript.apply(.final("One."))
        transcript.apply(.final("Two."))
        transcript.setTranslation("二。", for: 1)
        transcript.setTranslation("一。", for: 0)
        #expect(transcript.currentLines.translation == "二。")
    }

    @Test("A translation for an unknown entry is ignored")
    func unknownTranslationIgnored() {
        var transcript = Transcript()
        transcript.apply(.final("One."))
        transcript.setTranslation("？", for: 7)
        #expect(transcript.entries[0].translation == nil)
        #expect(transcript.currentLines.translation.isEmpty)
    }

    @Test("A blank translation counts as none")
    func blankTranslationIgnored() {
        var transcript = Transcript()
        transcript.apply(.final("One."))
        transcript.setTranslation("  ", for: 0)
        #expect(transcript.entries[0].translation == nil)
    }

    @Test("A very long partial shows only its end on the original row")
    func longPartialShowsTail() {
        var transcript = Transcript()
        let long = (1...60).map { "word\($0)" }.joined(separator: " ")
        transcript.apply(.partial(long))
        let shown = transcript.currentLines.original
        #expect(shown.hasPrefix("…"))
        #expect(shown.hasSuffix("word60"))
        #expect(shown.count < long.count)
        #expect(transcript.pending == long)
    }

    @Test("Resetting clears everything and restarts numbering")
    func reset() {
        var transcript = Transcript()
        transcript.apply(.final("One."))
        transcript.apply(.partial("Two"))
        transcript.reset()
        #expect(transcript.entries.isEmpty)
        #expect(transcript.currentLines.rows.isEmpty)
        #expect(transcript.apply(.final("Again."))?.id == 0)
    }
}

@Suite("CaptionText")
struct CaptionTextTests {
    @Test("Text within the limit is unchanged")
    func shortIsUnchanged() {
        #expect(CaptionText.tail(of: "Hello world", width: 20) == "Hello world")
    }

    @Test("Long spaced text keeps whole words from its end")
    func longLatinCutsAtWord() {
        #expect(CaptionText.tail(of: "one two three four five", width: 12) == "…four five")
    }

    @Test("A wide character counts as two columns")
    func wideCharactersCountDouble() {
        #expect(CaptionText.width(of: "abc") == 3)
        #expect(CaptionText.width(of: "字幕") == 4)
        #expect(CaptionText.width(of: "a字") == 3)
    }

    @Test("Long unspaced text is cut by characters")
    func longCJKCutsByCharacter() {
        #expect(CaptionText.tail(of: "これはテスト用の字幕です", width: 10) == "…字幕です")
    }

    @Test("A single word longer than the limit is cut inside the word")
    func oversizedWord() {
        #expect(CaptionText.tail(of: "abcdefghijklmnop", width: 6) == "…lmnop")
    }

    @Test("Empty text stays empty")
    func empty() {
        #expect(CaptionText.tail(of: "", width: 10) == "")
    }
}

@Suite("SourceLanguage")
struct SourceLanguageTests {
    @Test("English and Japanese are offered, English first")
    func allCases() {
        #expect(SourceLanguage.allCases == [.english, .japanese])
    }

    @Test("Each language names the locale to recognize")
    func localeIdentifiers() {
        #expect(SourceLanguage.english.localeIdentifier == "en-US")
        #expect(SourceLanguage.japanese.localeIdentifier == "ja-JP")
    }

    @Test("Each language names the language to translate from")
    func languageCodes() {
        #expect(SourceLanguage.english.languageCode == "en")
        #expect(SourceLanguage.japanese.languageCode == "ja")
    }

    @Test("A language survives being stored and read back")
    func rawValueRoundTrip() {
        for language in SourceLanguage.allCases {
            #expect(SourceLanguage(rawValue: language.rawValue) == language)
        }
        #expect(SourceLanguage(rawValue: "klingon") == nil)
    }
}

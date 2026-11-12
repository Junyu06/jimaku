import JimakuCore
import Testing

@Suite("Sentence splitting")
struct SentenceSplittingTests {
    @Test("Text without an ending is all remainder")
    func noEnding() {
        let split = CaptionText.sentences(in: "How are you")
        #expect(split.complete.isEmpty)
        #expect(split.remainder == "How are you")
    }

    @Test("A finished sentence is split from what follows")
    func latin() {
        let split = CaptionText.sentences(in: "Hello world. How are")
        #expect(split.complete == ["Hello world."])
        #expect(split.remainder == "How are")
    }

    @Test("Japanese and Chinese endings split without spaces")
    func cjk() {
        let split = CaptionText.sentences(in: "こんにちは。元気ですか？はい")
        #expect(split.complete == ["こんにちは。", "元気ですか？"])
        #expect(split.remainder == "はい")
    }

    @Test("Text that ends with an ending has no remainder")
    func endsComplete() {
        let split = CaptionText.sentences(in: "Hello world.")
        #expect(split.complete == ["Hello world."])
        #expect(split.remainder.isEmpty)
    }

    @Test("A period inside a number or an initialism does not end a sentence")
    func periodsThatAreNotEndings() {
        #expect(CaptionText.sentences(in: "It costs 3.5 dollars").complete.isEmpty)
        #expect(CaptionText.sentences(in: "The U.S. team won").complete.isEmpty)
    }

    @Test("Several ending marks in a row end one sentence")
    func repeatedEndings() {
        let split = CaptionText.sentences(in: "Really?! Yes.")
        #expect(split.complete == ["Really?!", "Yes."])
    }

    @Test("A closing quote stays with its sentence")
    func closingQuote() {
        let split = CaptionText.sentences(in: "「行こう。」と言った")
        #expect(split.complete == ["「行こう。」"])
        #expect(split.remainder == "と言った")
    }

    @Test("Empty text has nothing")
    func empty() {
        let split = CaptionText.sentences(in: "  ")
        #expect(split.complete.isEmpty)
        #expect(split.remainder.isEmpty)
    }
}

@Suite("Transcript")
struct TranscriptTests {
    @Test("A new transcript has nothing to show")
    func newIsEmpty() {
        let transcript = Transcript()
        #expect(transcript.entries.isEmpty)
        #expect(transcript.pending.isEmpty)
        #expect(transcript.currentLines.rows.isEmpty)
    }

    @Test("An unfinished partial is shown but not kept")
    func partialIsPending() {
        var transcript = Transcript()
        let settled = transcript.apply(.partial("Hello wor"))
        #expect(settled.isEmpty)
        #expect(transcript.entries.isEmpty)
        #expect(transcript.pending == "Hello wor")
        #expect(transcript.currentLines.original == "Hello wor")
    }

    @Test("A sentence that finishes inside a partial settles at once, without waiting for the recognizer")
    func sentenceSettlesInsidePartial() {
        var transcript = Transcript()
        let settled = transcript.apply(.partial("Hello world. How are"))
        #expect(settled == [Transcript.Entry(id: 0, original: "Hello world.", translation: nil)])
        #expect(transcript.pending == "How are")
    }

    @Test("A sentence settled from a partial is not settled again as the partial grows")
    func noDuplicateSettling() {
        var transcript = Transcript()
        transcript.apply(.partial("One. Two"))
        let settled = transcript.apply(.partial("One. Two. Three"))
        #expect(settled.map(\.original) == ["Two."])
        #expect(transcript.entries.map(\.original) == ["One.", "Two."])
        #expect(transcript.pending == "Three")
    }

    @Test("The final result settles only what the partials had not")
    func finalSettlesTheRest() {
        var transcript = Transcript()
        transcript.apply(.partial("One. Two"))
        let settled = transcript.apply(.final("One. Two is here"))
        #expect(settled.map(\.original) == ["Two is here"])
        #expect(transcript.entries.map(\.original) == ["One.", "Two is here"])
        #expect(transcript.pending.isEmpty)
    }

    @Test("A final result with no partial before it settles every sentence in it")
    func finalAlone() {
        var transcript = Transcript()
        let settled = transcript.apply(.final(" Hello world. Bye. "))
        #expect(settled.map(\.original) == ["Hello world.", "Bye."])
        #expect(settled.map(\.id) == [0, 1])
    }

    @Test("After a final result, the next speech starts a fresh count")
    func nextUtteranceStartsFresh() {
        var transcript = Transcript()
        transcript.apply(.partial("One. Two"))
        transcript.apply(.final("One. Two."))
        let settled = transcript.apply(.partial("Three. Four"))
        #expect(settled.map(\.original) == ["Three."])
        #expect(transcript.entries.map(\.original) == ["One.", "Two.", "Three."])
    }

    @Test("An empty final result clears the partial and adds nothing")
    func emptyFinal() {
        var transcript = Transcript()
        transcript.apply(.partial("uh"))
        #expect(transcript.apply(.final("  ")).isEmpty)
        #expect(transcript.entries.isEmpty)
        #expect(transcript.pending.isEmpty)
    }

    @Test("The original row runs on from settled sentences into the speech in progress")
    func originalRowRunsOn() {
        var transcript = Transcript()
        transcript.apply(.partial("One. Two is"))
        #expect(transcript.currentLines.original == "One. Two is")
    }

    @Test("Japanese sentences run on without added spaces")
    func originalRowRunsOnWithoutSpaces() {
        var transcript = Transcript()
        transcript.apply(.partial("そうです。はい"))
        #expect(transcript.currentLines.original == "そうです。はい")
    }

    @Test("Translations run on in order, newest last")
    func translationsRunOn() {
        var transcript = Transcript()
        transcript.apply(.final("One. Two."))
        transcript.setTranslation("二。", for: 1)
        transcript.setTranslation("一。", for: 0)
        #expect(transcript.currentLines.translation == "一。二。")
    }

    @Test("A sentence not translated yet is skipped rather than holding the others back")
    func untranslatedSentenceIsSkipped() {
        var transcript = Transcript()
        transcript.apply(.final("One. Two."))
        transcript.setTranslation("二。", for: 1)
        #expect(transcript.currentLines.translation == "二。")
    }

    @Test("The speech in progress shows its provisional translation after the settled ones")
    func provisionalTranslationFollows() {
        var transcript = Transcript()
        transcript.apply(.partial("One. Two is"))
        transcript.setTranslation("一。", for: 0)
        transcript.setPendingTranslation("二是", of: "Two is")
        #expect(transcript.pendingTranslation == "二是")
        #expect(transcript.currentLines.translation == "一。二是")
    }

    @Test("A provisional translation of an earlier version of the same clause is still shown")
    func provisionalOfEarlierVersion() {
        var transcript = Transcript()
        transcript.apply(.partial("Two is"))
        transcript.apply(.partial("Two is here"))
        transcript.setPendingTranslation("二是", of: "Two is")
        #expect(transcript.pendingTranslation == "二是")
    }

    @Test("A provisional translation of a clause that is gone is dropped")
    func staleProvisionalIsDropped() {
        var transcript = Transcript()
        transcript.apply(.partial("Two is"))
        transcript.apply(.partial("Two is here. Three"))
        transcript.setPendingTranslation("二是", of: "Two is")
        #expect(transcript.pendingTranslation == nil)
    }

    @Test("Settling a clause removes its provisional translation")
    func settlingClearsProvisional() {
        var transcript = Transcript()
        transcript.apply(.partial("Two is"))
        transcript.setPendingTranslation("二是", of: "Two is")
        transcript.apply(.partial("Two is here. Three"))
        #expect(transcript.pendingTranslation == nil)
        transcript.apply(.partial("Three is"))
        transcript.setPendingTranslation("三是", of: "Three is")
        transcript.apply(.final("Two is here. Three is done."))
        #expect(transcript.pendingTranslation == nil)
    }

    @Test("Both rows show only their end when there is too much text")
    func rowsShowTheEnd() {
        var transcript = Transcript()
        let sentences = (1...30).map { "Sentence number \($0)." }
        transcript.apply(.final(sentences.joined(separator: " ")))
        for entry in transcript.entries {
            transcript.setTranslation("第\(entry.id + 1)句的翻译。", for: entry.id)
        }
        let lines = transcript.currentLines
        #expect(lines.original.hasPrefix("…"))
        #expect(lines.original.hasSuffix("Sentence number 30."))
        #expect(CaptionText.width(of: lines.original) <= Transcript.originalRowWidth)
        #expect(lines.translation.hasPrefix("…"))
        #expect(lines.translation.hasSuffix("第30句的翻译。"))
        #expect(CaptionText.width(of: lines.translation) <= Transcript.translationRowWidth)
    }

    @Test("A translation for an unknown entry, or a blank one, is ignored")
    func badTranslationsIgnored() {
        var transcript = Transcript()
        transcript.apply(.final("One."))
        transcript.setTranslation("？", for: 7)
        transcript.setTranslation("  ", for: 0)
        #expect(transcript.entries[0].translation == nil)
        #expect(transcript.currentLines.translation.isEmpty)
    }

    @Test("Resetting clears everything and restarts numbering")
    func reset() {
        var transcript = Transcript()
        transcript.apply(.partial("One. Two"))
        transcript.setPendingTranslation("二", of: "Two")
        transcript.reset()
        #expect(transcript.entries.isEmpty)
        #expect(transcript.currentLines.rows.isEmpty)
        #expect(transcript.apply(.final("Again.")).first?.id == 0)
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

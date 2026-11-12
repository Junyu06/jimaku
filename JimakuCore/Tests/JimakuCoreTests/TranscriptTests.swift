import JimakuCore
import Testing

@Suite("Transcript")
struct TranscriptTests {
    private let rules = ChunkRules(clauseMinimum: 12, limit: 36)

    private func transcript() -> Transcript { Transcript(rules: rules) }

    @Test("A new transcript has nothing")
    func startsEmpty() {
        let transcript = transcript()
        #expect(transcript.entries.isEmpty)
        #expect(transcript.pending == "")
    }

    @Test("A first guess is speech in progress, not kept yet")
    func firstGuess() {
        var transcript = transcript()
        let settled = transcript.apply(.partial("はい、そうです。"), at: 0)
        #expect(settled.isEmpty)
        #expect(transcript.entries.isEmpty)
        #expect(transcript.pending == "はい、そうです。")
    }

    @Test("A sentence is kept once it has stood unchanged for a moment")
    func stableSentenceIsKept() {
        var transcript = transcript()
        transcript.apply(.partial("はい、そうです。"), at: 0)
        let settled = transcript.apply(.partial("はい、そうです。それで"), at: 1)
        #expect(settled.map(\.original) == ["はい、そうです。"])
        #expect(transcript.entries.map(\.original) == ["はい、そうです。"])
        #expect(transcript.pending == "それで")
    }

    @Test("A sentence is not kept before it has stood long enough")
    func tooSoon() {
        var transcript = transcript()
        transcript.apply(.partial("はい、そうです。"), at: 0)
        let settled = transcript.apply(.partial("はい、そうです。それで"), at: 0.3)
        #expect(settled.isEmpty)
        #expect(transcript.pending == "はい、そうです。それで")
    }

    @Test("A kept sentence does not change when the recognizer drops its period later")
    func keptSentenceIsFrozen() {
        var transcript = transcript()
        transcript.apply(.partial("ゆっくり説明してください。"), at: 0)
        transcript.apply(.partial("ゆっくり説明してください。先生"), at: 1)
        // The period goes away, as it does on a device, and comes back later.
        transcript.apply(.partial("ゆっくり説明してください先生サンドイッチ"), at: 2)
        #expect(transcript.entries.map(\.original) == ["ゆっくり説明してください。"])
        #expect(transcript.pending == "先生サンドイッチ")
        transcript.apply(.partial("ゆっくり説明してください。先生サンドイッチを"), at: 2.1)
        #expect(transcript.entries.map(\.original) == ["ゆっくり説明してください。"])
        #expect(transcript.pending == "先生サンドイッチを")
    }

    @Test("A rewrite restarts the wait for the rewritten part")
    func rewriteRestartsTheWait() {
        var transcript = transcript()
        transcript.apply(.partial("こちちらにります。"), at: 0)
        // The recognizer corrects itself a second later: this text is new.
        let afterFix = transcript.apply(.partial("こちらになります。状態"), at: 1)
        #expect(afterFix.isEmpty)
        let later = transcript.apply(.partial("こちらになります。状態を確認"), at: 2)
        #expect(later.map(\.original) == ["こちらになります。"])
    }

    @Test("The final result keeps everything that was not kept yet")
    func finalKeepsTheRest() {
        var transcript = transcript()
        transcript.apply(.partial("はい、そうです。"), at: 0)
        transcript.apply(.partial("はい、そうです。それで"), at: 1)
        let settled = transcript.apply(.final("はい、そうです。それでいいです。"), at: 1.2)
        #expect(settled.map(\.original) == ["それでいいです。"])
        #expect(transcript.entries.map(\.original) == ["はい、そうです。", "それでいいです。"])
        #expect(transcript.pending == "")
    }

    @Test("A final result with no guess before it is kept sentence by sentence")
    func finalAlone() {
        var transcript = transcript()
        let settled = transcript.apply(.final("Hello there. How are you"), at: 0)
        #expect(settled.map(\.original) == ["Hello there.", "How are you"])
        #expect(settled.map(\.id) == [0, 1])
    }

    @Test("A final result that punctuates differently repeats nothing")
    func finalWithOtherPunctuation() {
        var transcript = transcript()
        transcript.apply(.partial("so I walked into the store yesterday. and the guy"), at: 0)
        transcript.apply(.partial("so I walked into the store yesterday. and the guy behind"), at: 1)
        #expect(transcript.entries.map(\.original) == ["so I walked into the store yesterday."])
        transcript.apply(.final("So I walked into the store yesterday, and the guy behind the counter."), at: 2)
        #expect(
            transcript.entries.map(\.original) == [
                "so I walked into the store yesterday.", "and the guy behind the counter.",
            ])
    }

    @Test("After a final result the next speech starts from nothing")
    func nextStretch() {
        var transcript = transcript()
        transcript.apply(.final("Hello there."), at: 0)
        transcript.apply(.partial("How are"), at: 1)
        #expect(transcript.pending == "How are")
        let settled = transcript.apply(.final("How are you."), at: 2)
        #expect(settled.map(\.original) == ["How are you."])
        #expect(settled.map(\.id) == [1])
    }

    @Test("An empty final result clears the speech in progress and keeps nothing")
    func emptyFinal() {
        var transcript = transcript()
        transcript.apply(.partial("uh"), at: 0)
        let settled = transcript.apply(.final(""), at: 1)
        #expect(settled.isEmpty)
        #expect(transcript.entries.isEmpty)
        #expect(transcript.pending == "")
    }

    @Test("Long speech without any mark is kept in pieces while it goes on")
    func longSpeechIsKeptInPieces() {
        var transcript = transcript()
        let text = "今日行くの行かないのゆっくり説明してくださいと言われたので"
        transcript.apply(.partial(text), at: 0)
        let settled = transcript.apply(.partial(text + "先生"), at: 1)
        #expect(settled.map(\.original) == ["今日行くの行かないのゆっくり"])
        #expect(transcript.pending == "説明してくださいと言われたので先生")
    }

    @Test("Speech that has stopped growing is kept as it is, without waiting for a mark")
    func pauseEndsAPiece() {
        var transcript = transcript()
        transcript.apply(.partial("それでいいと思う"), at: 0)
        // The next burst of guesses brings nothing new: the speaker has paused.
        let settled = transcript.apply(.partial("それでいいと思う"), at: 1)
        #expect(settled.map(\.original) == ["それでいいと思う"])
        #expect(transcript.pending == "")
    }

    @Test("Speech that is still growing is not cut for a pause")
    func growingSpeechIsNotCut() {
        var transcript = transcript()
        transcript.apply(.partial("それでいい"), at: 0)
        let settled = transcript.apply(.partial("それでいいと思う"), at: 1)
        #expect(settled.isEmpty)
        #expect(transcript.pending == "それでいいと思う")
    }

    @Test("After a pause the speech that follows starts a new piece")
    func speechAfterAPause() {
        var transcript = transcript()
        transcript.apply(.partial("それでいいと思う"), at: 0)
        transcript.apply(.partial("それでいいと思う"), at: 2)
        let settled = transcript.apply(.partial("それでいいと思う次は"), at: 3)
        #expect(settled.isEmpty)
        #expect(transcript.entries.map(\.original) == ["それでいいと思う"])
        #expect(transcript.pending == "次は")
    }

    @Test("A guess that gets shorter is a change, not a pause")
    func shorterGuessIsNotAPause() {
        var transcript = transcript()
        transcript.apply(.partial("I like reading"), at: 0)
        #expect(transcript.apply(.partial("I like read"), at: 1).isEmpty)
        transcript.apply(.partial("I like reading books"), at: 1.01)
        transcript.apply(.final("I like reading books."), at: 1.1)
        #expect(transcript.entries.map(\.original) == ["I like reading books."])
    }

    @Test("Time passing without any update also ends a piece")
    func pauseWithoutUpdates() {
        var transcript = transcript()
        transcript.apply(.partial("それでいいと思う"), at: 0)
        // The usual gap between two bursts of guesses, about a second, is not a pause.
        #expect(transcript.elapse(to: 1).isEmpty)
        #expect(transcript.elapse(to: 2.9).isEmpty)
        #expect(transcript.elapse(to: 3).map(\.original) == ["それでいいと思う"])
        #expect(transcript.pending == "")
        #expect(transcript.elapse(to: 6).isEmpty)
        #expect(transcript.entries.count == 1)
    }

    @Test("The wait for a pause starts over with every change")
    func pauseWaitsFromTheLastChange() {
        var transcript = transcript()
        transcript.apply(.partial("I like reading"), at: 0)
        transcript.apply(.partial("I love reading"), at: 0.5)
        #expect(transcript.elapse(to: 3.4).isEmpty)
        #expect(transcript.elapse(to: 3.5).map(\.original) == ["I love reading"])
    }

    @Test("Time passing does nothing when no speech is in progress")
    func elapseWithoutSpeech() {
        var transcript = transcript()
        #expect(transcript.elapse(to: 5).isEmpty)
        transcript.apply(.final("Hello there."), at: 6)
        #expect(transcript.elapse(to: 9).isEmpty)
        #expect(transcript.entries.count == 1)
    }

    @Test("Time passing does not hand a failed entry out again; only an update does")
    func elapseDoesNotRetry() {
        var transcript = transcript()
        transcript.apply(.final("Hello there."), at: 0)
        transcript.translationFailed(for: 0)
        #expect(transcript.elapse(to: 5).isEmpty)
        #expect(transcript.apply(.partial("How"), at: 6).map(\.id) == [0])
    }

    @Test("A guess that shrinks below what was kept leaves nothing in progress")
    func shrinkingGuess() {
        var transcript = transcript()
        transcript.apply(.partial("はい、そうです。"), at: 0)
        transcript.apply(.partial("はい、そうです。それ"), at: 1)
        transcript.apply(.partial("はい、そう"), at: 2)
        #expect(transcript.entries.map(\.original) == ["はい、そうです。"])
        #expect(transcript.pending == "")
    }

    // MARK: Translations

    @Test("A translation goes to its entry")
    func translation() {
        var transcript = transcript()
        transcript.apply(.final("Hello there. How are you"), at: 0)
        transcript.setTranslation(" 你好。 ", for: 0)
        #expect(transcript.entries.map(\.translation) == ["你好。", nil])
    }

    @Test("A translation for an unknown entry, or a blank one, is ignored")
    func strayTranslation() {
        var transcript = transcript()
        transcript.apply(.final("Hello there."), at: 0)
        transcript.setTranslation("你好", for: 7)
        transcript.setTranslation("  ", for: 0)
        #expect(transcript.entries.map(\.translation) == [nil])
    }

    @Test("After a failed translation the entry is handed out again with the next update")
    func failedTranslationIsRetried() {
        var transcript = transcript()
        let first = transcript.apply(.final("Hello there."), at: 0)
        transcript.translationFailed(for: first[0].id)
        let again = transcript.apply(.partial("How"), at: 1)
        #expect(again.map(\.id) == [0])
        // Only once per failure.
        #expect(transcript.apply(.partial("How are"), at: 1.1).isEmpty)
    }

    @Test("An entry that was translated meanwhile is not handed out again")
    func noRetryAfterSuccess() {
        var transcript = transcript()
        transcript.apply(.final("Hello there."), at: 0)
        transcript.translationFailed(for: 0)
        transcript.setTranslation("你好。", for: 0)
        #expect(transcript.apply(.partial("How"), at: 1).isEmpty)
    }

    @Test("An old entry is not retried")
    func oldEntriesAreNotRetried() {
        var transcript = transcript()
        transcript.apply(.final("One. Two. Three. Four. Five."), at: 0)
        transcript.translationFailed(for: 0)
        #expect(transcript.apply(.partial("Six"), at: 1).isEmpty)
    }

    @Test("Resetting clears everything and restarts numbering")
    func reset() {
        var transcript = transcript()
        transcript.apply(.final("Hello there."), at: 0)
        transcript.apply(.partial("How"), at: 1)
        transcript.reset()
        #expect(transcript.entries.isEmpty)
        #expect(transcript.pending == "")
        #expect(transcript.apply(.final("Again."), at: 2).map(\.id) == [0])
    }
}

@Suite("Transcript on recorded speech")
struct RecordedTranscriptTests {
    private struct Run {
        var transcript: Transcript
        /// Every entry as it was when first kept.
        var firstSeen: [Transcript.Entry] = []
        var widestPending = 0
        var entriesBeforeLastFinal = 0
        var changed = false
    }

    private func replay(_ steps: [RecordedSpeech.Step], rules: ChunkRules) -> Run {
        var run = Run(transcript: Transcript(rules: rules))
        for step in steps {
            if step.isFinal { run.entriesBeforeLastFinal = run.transcript.entries.count }
            run.transcript.apply(step.update, at: step.time)
            let entries = run.transcript.entries
            if Array(entries.prefix(run.firstSeen.count)).map(\.original) != run.firstSeen.map(\.original) {
                run.changed = true
            }
            run.firstSeen.append(contentsOf: entries.dropFirst(run.firstSeen.count))
            run.widestPending = max(run.widestPending, CaptionText.width(of: run.transcript.pending))
        }
        return run
    }

    private func spoken(_ text: String) -> String {
        String(text.filter { CaptionText.spokenCount(in: String($0)) == 1 })
    }

    @Test("Continuous Japanese is kept sentence by sentence long before the recognizer finalizes it")
    func japaneseIsKeptEarly() {
        let run = replay(RecordedSpeech.japanese, rules: .japanese)
        // The recording has five sentences; two of them are cut at a comma.
        #expect(run.entriesBeforeLastFinal == 7)
        #expect(
            run.transcript.entries.map(\.original) == [
                "今日は朝からとてもいい天気だったので、",
                "近くの公園まで散歩に行ってきました。",
                "途中で新しいパン屋さんを見つけて、",
                "焼きたてのクロワッサンを 2つ買いました。",
                "店員さんがとても親切でおすすめのコーヒーも教えてくれました。",
                "家に帰ってから食べてみたら本当に美味しかったです。",
                "また来週も行ってみようと思います。",
            ])
    }

    @Test("Checking for a pause ten times a second between guesses cuts nothing extra")
    func ticksBetweenBurstsAreNotPauses() {
        // Guesses come about a second apart. The gaps between them are not pauses.
        var transcript = Transcript(rules: .japanese)
        var previous = 0.0
        for step in RecordedSpeech.japanese {
            var tick = previous + 0.1
            while tick < step.time {
                transcript.elapse(to: tick)
                tick += 0.1
            }
            transcript.apply(step.update, at: step.time)
            previous = step.time
        }
        #expect(transcript.entries.count == 7)
        #expect(transcript.entries.first?.original == "今日は朝からとてもいい天気だったので、")
    }

    @Test("What was kept from the Japanese recording never changed afterwards")
    func japaneseIsFrozen() {
        let run = replay(RecordedSpeech.japanese, rules: .japanese)
        #expect(!run.changed)
    }

    @Test("The Japanese pieces together say what the final result says, nothing lost or repeated")
    func japaneseIsComplete() {
        let run = replay(RecordedSpeech.japanese, rules: .japanese)
        let final = RecordedSpeech.japanese.last { $0.isFinal }!.text
        #expect(spoken(run.transcript.entries.map(\.original).joined()) == spoken(final))
    }

    @Test("The speech in progress never grows much beyond one piece")
    func pendingStaysShort() {
        let japanese = replay(RecordedSpeech.japanese, rules: .japanese)
        #expect(japanese.widestPending <= ChunkRules.japanese.limit * 2)
        let english = replay(RecordedSpeech.english, rules: .english)
        #expect(english.widestPending <= ChunkRules.english.limit * 2)
    }

    @Test("No piece is much longer than the limit")
    func piecesStayShort() {
        let japanese = replay(RecordedSpeech.japanese, rules: .japanese)
        for entry in japanese.transcript.entries {
            #expect(CaptionText.width(of: entry.original) <= ChunkRules.japanese.limit * 2)
        }
        let english = replay(RecordedSpeech.english, rules: .english)
        for entry in english.transcript.entries {
            #expect(CaptionText.width(of: entry.original) <= ChunkRules.english.limit * 2)
        }
    }

    @Test("The English pieces together say what the final results say")
    func englishIsComplete() {
        let run = replay(RecordedSpeech.english, rules: .english)
        let finals = RecordedSpeech.english.filter(\.isFinal).map(\.text).joined()
        #expect(!run.changed)
        #expect(spoken(run.transcript.entries.map(\.original).joined()).lowercased() == spoken(finals).lowercased())
    }
}

@Suite("SourceLanguage")
struct SourceLanguageTests {
    @Test("English and Japanese are offered, English first")
    func cases() {
        #expect(SourceLanguage.allCases == [.english, .japanese])
    }

    @Test("Each language names the locale to recognize")
    func locales() {
        #expect(SourceLanguage.english.localeIdentifier == "en-US")
        #expect(SourceLanguage.japanese.localeIdentifier == "ja-JP")
    }

    @Test("Each language names the language to translate from")
    func languageCodes() {
        #expect(SourceLanguage.english.languageCode == "en")
        #expect(SourceLanguage.japanese.languageCode == "ja")
    }

    @Test("A language survives being stored and read back")
    func rawValues() {
        for language in SourceLanguage.allCases {
            #expect(SourceLanguage(rawValue: language.rawValue) == language)
        }
    }

    @Test("Each language has its own rules for cutting speech into pieces")
    func chunkRules() {
        #expect(SourceLanguage.japanese.chunkRules == .japanese)
        #expect(SourceLanguage.english.chunkRules == .english)
        #expect(ChunkRules.japanese.limit < ChunkRules.english.limit)
    }
}

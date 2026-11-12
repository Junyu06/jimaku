import JimakuCore
import Testing

@Suite("Generation")
struct GenerationTests {
    @Test("A token is current until the next one is issued")
    func tokenGoesStale() {
        var generation = Generation()
        let first = generation.advance()
        #expect(generation.isCurrent(first))
        let second = generation.advance()
        #expect(generation.isCurrent(first) == false)
        #expect(generation.isCurrent(second))
    }

    @Test("Before anything is issued, no token is current")
    func nothingIssued() {
        var other = Generation()
        let foreign = other.advance()
        #expect(Generation().isCurrent(foreign) == false)
    }

    @Test("Invalidating makes every issued token stale")
    func invalidate() {
        var generation = Generation()
        let token = generation.advance()
        generation.invalidate()
        #expect(generation.isCurrent(token) == false)
    }
}

@Suite("CaptionPlaceholder")
struct CaptionPlaceholderTests {
    private func placeholder(
        recognition: CaptionPlaceholder.Readiness = .ready,
        audio: AudioAvailability = .receiving,
        translation: CaptionPlaceholder.Readiness = .ready,
        mode: CaptionStyle.Mode = .originalAndTranslation,
        hasSpeech: Bool = false
    ) -> CaptionPlaceholder {
        CaptionPlaceholder.choose(
            recognition: recognition,
            audio: audio,
            translation: translation,
            mode: mode,
            hasSpeech: hasSpeech
        )
    }

    @Test("A recognition failure is reported before anything else")
    func recognitionFailureFirst() {
        #expect(placeholder(recognition: .failed, audio: .notBroadcasting, translation: .failed) == .recognitionFailed)
    }

    @Test("Recognition still preparing is reported before audio problems")
    func preparingRecognition() {
        #expect(placeholder(recognition: .preparing, audio: .notBroadcasting) == .preparingRecognition)
    }

    @Test("Each audio state has its own message once recognition is ready")
    func audioStates() {
        #expect(placeholder(audio: .unavailable) == .audioUnavailable)
        #expect(placeholder(audio: .notBroadcasting) == .waitingForBroadcast)
        #expect(placeholder(audio: .stalled) == .noSound)
        #expect(placeholder(audio: .receiving) == .listening)
    }

    @Test("A translation problem is not reported while nothing has been said")
    func translationProblemWaitsForSpeech() {
        #expect(placeholder(translation: .failed, mode: .translationOnly, hasSpeech: false) == .listening)
    }

    @Test("In translation-only mode, speech without a translation yet says it is being translated")
    func translating() {
        #expect(placeholder(translation: .ready, mode: .translationOnly, hasSpeech: true) == .translating)
        #expect(placeholder(translation: .preparing, mode: .translationOnly, hasSpeech: true) == .preparingTranslation)
    }

    @Test("A translation failure is never reported as a recognition failure")
    func translationFailureIsItsOwnMessage() {
        #expect(placeholder(translation: .failed, mode: .translationOnly, hasSpeech: true) == .translationUnavailable)
    }
}

@Suite("Display mode fallback")
struct DisplayModeFallbackTests {
    @Test("Translation-only falls back to showing the original when translation cannot run")
    func fallsBackWithoutTranslation() {
        #expect(CaptionStyle.Mode.translationOnly.effective(translationAvailable: false) == .originalAndTranslation)
    }

    @Test("Translation-only stays as chosen while translation can run")
    func staysWhenAvailable() {
        #expect(CaptionStyle.Mode.translationOnly.effective(translationAvailable: true) == .translationOnly)
    }

    @Test("Both-lines mode is never changed")
    func bothLinesUnchanged() {
        #expect(CaptionStyle.Mode.originalAndTranslation.effective(translationAvailable: false) == .originalAndTranslation)
        #expect(CaptionStyle.Mode.originalAndTranslation.effective(translationAvailable: true) == .originalAndTranslation)
    }
}

@Suite("Review regressions")
struct ReviewRegressionTests {
    @Test("A label on its own line does not swallow the translation after it")
    func labelThenBlankLine() {
        #expect(TranslationPrompt.clean("翻译：\n\n你好") == "你好")
        #expect(TranslationPrompt.clean("Translation:\r\n你好") == "你好")
    }

    @Test("A quoted translation after a label is unwrapped")
    func labelAndQuotes() {
        #expect(TranslationPrompt.clean("译文：“你好。”") == "你好。")
    }

    @Test("A single line break inside the translation becomes a space")
    func innerLineBreak() {
        #expect(TranslationPrompt.clean("你好，\n世界。") == "你好， 世界。")
    }

    @Test("A width that leaves no room returns nothing")
    func tailWithoutRoom() {
        #expect(CaptionText.tail(of: "Hello", width: 0) == "")
        #expect(CaptionText.tail(of: "Hello", width: -3) == "")
        #expect(CaptionText.tail(of: "Hello", width: Int.min) == "")
    }

    @Test("Text that exactly fits is unchanged")
    func tailExactFit() {
        #expect(CaptionText.tail(of: "Hello", width: 5) == "Hello")
        #expect(CaptionText.tail(of: "字幕", width: 4) == "字幕")
    }

    @Test("Trailing whitespace does not cost the last word")
    func tailTrailingWhitespace() {
        #expect(CaptionText.tail(of: "abcdefghij ", width: 6) == "…fghij")
    }
}

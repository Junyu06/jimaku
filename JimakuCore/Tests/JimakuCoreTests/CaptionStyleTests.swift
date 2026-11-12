import JimakuCore
import Testing

@Suite("CaptionStyle")
struct CaptionStyleTests {
    @Test("By default captions are medium and show both lines")
    func defaults() {
        let style = CaptionStyle()
        #expect(style.textSize == .medium)
        #expect(style.mode == .originalAndTranslation)
    }

    @Test("Text sizes are offered small to large")
    func textSizes() {
        #expect(CaptionStyle.TextSize.allCases == [.small, .medium, .large])
    }

    @Test("Style choices survive being stored and read back")
    func rawValueRoundTrip() {
        for size in CaptionStyle.TextSize.allCases {
            #expect(CaptionStyle.TextSize(rawValue: size.rawValue) == size)
        }
        for mode in CaptionStyle.Mode.allCases {
            #expect(CaptionStyle.Mode(rawValue: mode.rawValue) == mode)
        }
    }
}

@Suite("TranslationEngine")
struct TranslationEngineTests {
    @Test("Language packs come first, then Apple Intelligence")
    func allCases() {
        #expect(TranslationEngine.allCases == [.languagePack, .appleIntelligence])
    }

    @Test("An engine survives being stored and read back")
    func rawValueRoundTrip() {
        for engine in TranslationEngine.allCases {
            #expect(TranslationEngine(rawValue: engine.rawValue) == engine)
        }
    }
}

@Suite("TranslationPrompt")
struct TranslationPromptTests {
    @Test("The instructions name both languages and ask for the translation alone")
    func instructions() {
        let english = TranslationPrompt.instructions(from: .english)
        #expect(english.contains("English"))
        #expect(english.contains("Simplified Chinese"))
        #expect(english.lowercased().contains("only"))
        #expect(TranslationPrompt.instructions(from: .japanese).contains("Japanese"))
    }

    @Test("A clean response is left alone")
    func cleanLeavesGoodText() {
        #expect(TranslationPrompt.clean("你好，世界。") == "你好，世界。")
    }

    @Test("Surrounding whitespace and quotes are removed")
    func cleanStripsQuotes() {
        #expect(TranslationPrompt.clean("  “你好，世界。”\n") == "你好，世界。")
        #expect(TranslationPrompt.clean("\"你好\"") == "你好")
        #expect(TranslationPrompt.clean("「你好」") == "你好")
    }

    @Test("A leading label is removed")
    func cleanStripsLabel() {
        #expect(TranslationPrompt.clean("翻译：你好") == "你好")
        #expect(TranslationPrompt.clean("译文: 你好") == "你好")
        #expect(TranslationPrompt.clean("Translation: 你好") == "你好")
    }

    @Test("Only the first paragraph is kept")
    func cleanKeepsFirstParagraph() {
        #expect(TranslationPrompt.clean("你好。\n\n（注：这是问候语）") == "你好。")
    }

    @Test("Quotes inside the sentence are kept")
    func cleanKeepsInnerQuotes() {
        #expect(TranslationPrompt.clean("他说“你好”就走了。") == "他说“你好”就走了。")
    }

    @Test("An empty response stays empty")
    func cleanEmpty() {
        #expect(TranslationPrompt.clean("  \n ") == "")
    }
}

import JimakuCore
import Testing

@Suite("CaptionLanguage")
struct CaptionLanguageTests {
    @Test("The languages are offered in a fixed order, English first")
    func catalog() {
        #expect(
            CaptionLanguage.all.map(\.identifier) == [
                "en", "ja", "zh-Hans", "zh-Hant", "ko", "es", "fr", "de", "it", "pt", "hi",
            ])
    }

    @Test("A language is found by its identifier, and an unknown identifier finds none")
    func lookup() {
        for language in CaptionLanguage.all {
            #expect(CaptionLanguage(identifier: language.identifier) == language)
        }
        #expect(CaptionLanguage(identifier: "ja") == .japanese)
        #expect(CaptionLanguage(identifier: "tlh") == nil)
        #expect(CaptionLanguage(identifier: "") == nil)
    }

    @Test("Each language that can be spoken names the locale to recognize")
    func recognizerLocales() {
        #expect(CaptionLanguage.english.recognizerLocale == "en-US")
        #expect(CaptionLanguage.japanese.recognizerLocale == "ja-JP")
        #expect(CaptionLanguage.simplifiedChinese.recognizerLocale == "zh-CN")
        #expect(CaptionLanguage.korean.recognizerLocale == "ko-KR")
        #expect(CaptionLanguage.portuguese.recognizerLocale == "pt-BR")
        #expect(
            CaptionLanguage.all.map(\.recognizerLocale) == [
                "en-US", "ja-JP", "zh-CN", nil, "ko-KR", "es-ES", "fr-FR", "de-DE", "it-IT", "pt-BR", "hi-IN",
            ])
        let locales = CaptionLanguage.all.compactMap(\.recognizerLocale)
        #expect(Set(locales).count == locales.count)
    }

    @Test("Traditional Chinese is a language to translate into, not one to listen for")
    func traditionalChineseIsWrittenOnly() {
        #expect(CaptionLanguage.traditionalChinese.recognizerLocale == nil)
        #expect(!CaptionLanguage.traditionalChinese.canBeSpoken)
        #expect(CaptionLanguage.all.filter { !$0.canBeSpoken } == [.traditionalChinese])
    }

    @Test("A language that is only written is spoken as the form of its family that can be")
    func spokenForm() {
        #expect(CaptionLanguage.traditionalChinese.spokenForm == .simplifiedChinese)
        #expect(CaptionLanguage.simplifiedChinese.spokenForm == .simplifiedChinese)
        #expect(CaptionLanguage.korean.spokenForm == .korean)
    }

    @Test("What the recognizer reports is tidied for Chinese only")
    func tidying() {
        #expect(CaptionLanguage.simplifiedChinese.tidying("我去了超市 ，买了牛奶 。") == "我去了超市，买了牛奶。")
        #expect(CaptionLanguage.japanese.tidying("東京 、大阪") == "東京 、大阪")
        #expect(CaptionLanguage.english.tidying("Yes , really 。") == "Yes , really 。")
        #expect(CaptionLanguage.korean.tidying("네 ，좋아요") == "네 ，좋아요")
    }

    @Test("The two written forms of Chinese are one family; every other language is its own")
    func families() {
        #expect(CaptionLanguage.simplifiedChinese.family == "zh")
        #expect(CaptionLanguage.traditionalChinese.family == "zh")
        #expect(CaptionLanguage.english.family == "en")
        #expect(Set(CaptionLanguage.all.map(\.family)).count == CaptionLanguage.all.count - 1)
    }

    @Test("Languages written in wide characters are cut like Japanese, the others like English")
    func chunkRules() {
        #expect(CaptionLanguage.japanese.chunkRules == .japanese)
        #expect(CaptionLanguage.simplifiedChinese.chunkRules == .japanese)
        #expect(CaptionLanguage.korean.chunkRules == .japanese)
        #expect(CaptionLanguage.english.chunkRules == .english)
        #expect(CaptionLanguage.spanish.chunkRules == .english)
        #expect(CaptionLanguage.hindi.chunkRules == .english)
        #expect(ChunkRules.japanese.limit < ChunkRules.english.limit)
    }

    @Test("Each language has an English name to give a language model, all different")
    func englishNames() {
        #expect(CaptionLanguage.simplifiedChinese.englishName == "Simplified Chinese")
        #expect(CaptionLanguage.traditionalChinese.englishName == "Traditional Chinese")
        #expect(CaptionLanguage.japanese.englishName == "Japanese")
        #expect(Set(CaptionLanguage.all.map(\.englishName)).count == CaptionLanguage.all.count)
    }

    @Test("The device's preferred languages pick the first one the app has")
    func preferred() {
        #expect(CaptionLanguage.preferred(among: ["zh-Hans-CN", "en-US"]) == .simplifiedChinese)
        #expect(CaptionLanguage.preferred(among: ["zh-Hant-HK"]) == .traditionalChinese)
        #expect(CaptionLanguage.preferred(among: ["zh-TW"]) == .traditionalChinese)
        #expect(CaptionLanguage.preferred(among: ["zh-CN"]) == .simplifiedChinese)
        #expect(CaptionLanguage.preferred(among: ["en-GB"]) == .english)
        #expect(CaptionLanguage.preferred(among: ["pt-PT", "ja-JP"]) == .portuguese)
        #expect(CaptionLanguage.preferred(among: ["ru-RU", "ko-KR"]) == .korean)
        #expect(CaptionLanguage.preferred(among: ["ru-RU"]) == nil)
        #expect(CaptionLanguage.preferred(among: []) == nil)
    }
}

@Suite("LanguagePair")
struct LanguagePairTests {
    @Test("Choosing a target of another family leaves the spoken language alone")
    func chooseTarget() {
        let pair = LanguagePair(spoken: .english, target: .simplifiedChinese)
        #expect(pair.choosing(target: .japanese) == LanguagePair(spoken: .english, target: .japanese))
    }

    @Test("Choosing the spoken language as the target swaps the two")
    func chooseTargetSwaps() {
        let pair = LanguagePair(spoken: .english, target: .simplifiedChinese)
        #expect(pair.choosing(target: .english) == LanguagePair(spoken: .simplifiedChinese, target: .english))
    }

    @Test("Choosing the target as the spoken language swaps the two")
    func chooseSpokenSwaps() {
        let pair = LanguagePair(spoken: .english, target: .simplifiedChinese)
        #expect(pair.choosing(spoken: .simplifiedChinese) == LanguagePair(spoken: .simplifiedChinese, target: .english))
        #expect(pair.choosing(spoken: .korean) == LanguagePair(spoken: .korean, target: .simplifiedChinese))
    }

    @Test("A target that is only written swaps in as the spoken form of its family")
    func swapFromTraditionalChinese() {
        let pair = LanguagePair(spoken: .japanese, target: .traditionalChinese)
        #expect(pair.choosing(target: .japanese) == LanguagePair(spoken: .simplifiedChinese, target: .japanese))
    }

    @Test("A swap that would leave both languages Chinese picks another one instead")
    func swapWithinChinese() {
        // The old spoken language is Chinese too, so English takes over as spoken.
        let chinese = LanguagePair(spoken: .simplifiedChinese, target: .english)
        #expect(
            chinese.choosing(target: .traditionalChinese)
                == LanguagePair(spoken: .english, target: .traditionalChinese))
        let toJapanese = LanguagePair(spoken: .simplifiedChinese, target: .japanese)
        #expect(
            toJapanese.choosing(target: .traditionalChinese)
                == LanguagePair(spoken: .japanese, target: .traditionalChinese))
    }

    @Test("A language that is only written is chosen as spoken in its spoken form")
    func chooseWrittenOnlyAsSpoken() {
        let pair = LanguagePair(spoken: .english, target: .french)
        #expect(
            pair.choosing(spoken: .traditionalChinese) == LanguagePair(spoken: .simplifiedChinese, target: .french))
        let toChinese = LanguagePair(spoken: .english, target: .traditionalChinese)
        #expect(
            toChinese.choosing(spoken: .traditionalChinese)
                == LanguagePair(spoken: .simplifiedChinese, target: .english))
    }

    @Test("Stored identifiers bring the pair back")
    func restore() {
        let pair = LanguagePair.restored(spoken: "ko", target: "en", legacySpoken: nil, preferred: ["zh-Hans-CN"])
        #expect(pair == LanguagePair(spoken: .korean, target: .english))
    }

    @Test("A choice stored by a version with only English and Japanese keeps translating into Simplified Chinese")
    func restoreLegacy() {
        let japanese = LanguagePair.restored(spoken: nil, target: nil, legacySpoken: "japanese", preferred: ["en-US"])
        #expect(japanese == LanguagePair(spoken: .japanese, target: .simplifiedChinese))
        let english = LanguagePair.restored(spoken: nil, target: nil, legacySpoken: "english", preferred: ["en-US"])
        #expect(english == LanguagePair(spoken: .english, target: .simplifiedChinese))
    }

    @Test("With nothing stored, the target is the device's language and the spoken language is English")
    func restoreFresh() {
        let chinese = LanguagePair.restored(spoken: nil, target: nil, legacySpoken: nil, preferred: ["zh-Hans-CN", "en"])
        #expect(chinese == LanguagePair(spoken: .english, target: .simplifiedChinese))
        let korean = LanguagePair.restored(spoken: nil, target: nil, legacySpoken: nil, preferred: ["ko-KR"])
        #expect(korean == LanguagePair(spoken: .english, target: .korean))
    }

    @Test("On a device in English, or in a language the app does not have, captions start as Japanese into English")
    func restoreFreshEnglish() {
        let english = LanguagePair.restored(spoken: nil, target: nil, legacySpoken: nil, preferred: ["en-US"])
        #expect(english == LanguagePair(spoken: .japanese, target: .english))
        let unknown = LanguagePair.restored(spoken: nil, target: nil, legacySpoken: nil, preferred: ["ru-RU"])
        #expect(unknown == LanguagePair(spoken: .japanese, target: .english))
    }

    @Test("Stored identifiers that cannot make a pair are repaired")
    func restoreBroken() {
        let unknown = LanguagePair.restored(spoken: "tlh", target: "xx", legacySpoken: nil, preferred: ["zh-Hans"])
        #expect(unknown == LanguagePair(spoken: .english, target: .simplifiedChinese))
        let unspoken = LanguagePair.restored(spoken: "zh-Hant", target: "en", legacySpoken: nil, preferred: [])
        #expect(unspoken == LanguagePair(spoken: .japanese, target: .english))
        let same = LanguagePair.restored(spoken: "zh-Hans", target: "zh-Hant", legacySpoken: nil, preferred: [])
        #expect(same == LanguagePair(spoken: .english, target: .traditionalChinese))
    }
}

@Suite("LanguageSupport")
struct LanguageSupportTests {
    private let toChinese = { (spoken: CaptionLanguage) in LanguagePair(spoken: spoken, target: .simplifiedChinese) }

    /// A device that recognizes English, Japanese, and Korean; has the packs for
    /// English and Japanese into Simplified Chinese, can download Korean; and
    /// whose language model knows English, Japanese, and both forms of Chinese.
    private var device: LanguageSupport {
        LanguageSupport(
            recognizable: [.english, .japanese, .korean],
            packs: [
                toChinese(.english): .installed,
                toChinese(.japanese): .installed,
                toChinese(.korean): .downloadable,
                LanguagePair(spoken: .japanese, target: .english): .installed,
            ],
            modelLanguages: [.english, .japanese, .simplifiedChinese, .traditionalChinese]
        )
    }

    @Test("A pair the system did not report has no language pack")
    func packStatus() {
        #expect(device.packStatus(for: toChinese(.english)) == .installed)
        #expect(device.packStatus(for: toChinese(.korean)) == .downloadable)
        #expect(device.packStatus(for: toChinese(.french)) == .unsupported)
        #expect(LanguageSupport().packStatus(for: toChinese(.english)) == .unsupported)
    }

    @Test("A language pack that is installed or can be downloaded makes the language-pack engine usable")
    func languagePackEngine() {
        #expect(device.engines(for: toChinese(.english)).contains(.languagePack))
        #expect(device.engines(for: toChinese(.korean)).contains(.languagePack))
        #expect(!device.engines(for: LanguagePair(spoken: .korean, target: .english)).contains(.languagePack))
    }

    @Test("The language model is usable when it knows both languages")
    func modelEngine() {
        #expect(device.engines(for: toChinese(.english)) == [.languagePack, .appleIntelligence])
        #expect(device.engines(for: toChinese(.korean)) == [.languagePack])
        #expect(device.engines(for: LanguagePair(spoken: .english, target: .traditionalChinese)) == [.appleIntelligence])
    }

    @Test("Two forms of one language are never translated into each other")
    func sameFamily() {
        var device = device
        device.recognizable.insert(.simplifiedChinese)
        let pair = LanguagePair(spoken: .simplifiedChinese, target: .traditionalChinese)
        device.packs[pair] = .installed
        #expect(device.engines(for: pair).isEmpty)
    }

    @Test("The preferred engine is used when it can be, otherwise the one that can")
    func preferredEngine() {
        #expect(device.engine(preferring: .appleIntelligence, for: toChinese(.english)) == .appleIntelligence)
        #expect(device.engine(preferring: .appleIntelligence, for: toChinese(.korean)) == .languagePack)
        #expect(
            device.engine(preferring: .languagePack, for: LanguagePair(spoken: .english, target: .traditionalChinese))
                == .appleIntelligence)
        // Nothing can translate the pair: the preference stands, and starting says why.
        #expect(device.engine(preferring: .languagePack, for: toChinese(.french)) == .languagePack)
    }

    @Test("The spoken languages offered are those the device recognizes and can translate into something")
    func spokenChoices() {
        #expect(device.spokenChoices == [.english, .japanese, .korean])
    }

    @Test("A language that is not recognized is not offered even with a language pack")
    func unrecognizedIsNotOffered() {
        var device = device
        device.packs[toChinese(.german)] = .installed
        #expect(!device.spokenChoices.contains(.german))
    }

    @Test("A language that is recognized but cannot be translated into anything is not offered")
    func untranslatableIsNotOffered() {
        var device = device
        device.recognizable.insert(.french)
        #expect(!device.spokenChoices.contains(.french))
    }

    @Test("The spoken language stays offered when it is of the target's family, so choosing it can swap the two")
    func spokenChoicesIgnoreTheTarget() {
        var device = device
        device.recognizable.insert(.simplifiedChinese)
        device.packs[LanguagePair(spoken: .simplifiedChinese, target: .english)] = .installed
        #expect(device.spokenChoices == [.english, .japanese, .simplifiedChinese, .korean])
    }

    @Test("The targets offered are those some spoken language can be translated into")
    func targetChoices() {
        #expect(device.targetChoices == [.english, .japanese, .simplifiedChinese, .traditionalChinese])
        #expect(LanguageSupport().targetChoices == [])
    }

    @Test("A pair the device can do is left alone")
    func settledKeeps() {
        #expect(device.settled(toChinese(.korean), keeping: .spoken) == toChinese(.korean))
        #expect(device.settled(toChinese(.korean), keeping: .target) == toChinese(.korean))
    }

    @Test("When the spoken language was just chosen, the target gives way")
    func settledKeepingSpoken() {
        // Korean cannot go into English here; Simplified Chinese is the first it can go into.
        #expect(
            device.settled(LanguagePair(spoken: .korean, target: .english), keeping: .spoken) == toChinese(.korean))
    }

    @Test("When the target was just chosen, the spoken language gives way")
    func settledKeepingTarget() {
        #expect(
            device.settled(LanguagePair(spoken: .korean, target: .english), keeping: .target)
                == LanguagePair(spoken: .japanese, target: .english))
    }

    @Test("A side the device cannot do at all gives way even when it was the one to keep")
    func settledWhenTheKeptSideIsImpossible() {
        #expect(device.settled(toChinese(.french), keeping: .spoken) == toChinese(.english))
        // English can be translated into Japanese, by the model.
        #expect(
            device.settled(LanguagePair(spoken: .english, target: .french), keeping: .target)
                == LanguagePair(spoken: .english, target: .japanese))
    }

    @Test("A spoken language the device does not recognize gives way even when an engine could translate it")
    func settledUnrecognized() {
        // The model knows French and English, and there is a pack the other way round.
        let device = LanguageSupport(
            recognizable: [.english],
            packs: [LanguagePair(spoken: .english, target: .french): .installed],
            modelLanguages: [.english, .french]
        )
        let pair = LanguagePair(spoken: .french, target: .english)
        #expect(!device.canCaption(pair))
        #expect(device.settled(pair, keeping: .spoken) == LanguagePair(spoken: .english, target: .french))
        #expect(device.settled(pair, keeping: .target) == LanguagePair(spoken: .english, target: .french))
    }

    @Test("When neither side can be done, the first pair the device can do is used")
    func settledWithNeither() {
        #expect(
            device.settled(LanguagePair(spoken: .french, target: .german), keeping: .spoken)
                == LanguagePair(spoken: .english, target: .japanese))
    }

    @Test("A device that reports nothing leaves the choice as it is")
    func settledWithNothing() {
        #expect(LanguageSupport().settled(toChinese(.french), keeping: .spoken) == toChinese(.french))
    }
}

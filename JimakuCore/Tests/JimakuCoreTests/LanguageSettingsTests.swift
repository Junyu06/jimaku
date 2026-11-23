import JimakuCore
import Testing

@Suite("LanguageSettings")
struct LanguageSettingsTests {
    private let toChinese = { (spoken: CaptionLanguage) in LanguagePair(spoken: spoken, target: .simplifiedChinese) }

    private func settings(
        _ pair: LanguagePair? = nil,
        engine: TranslationEngine = .languagePack
    ) -> LanguageSettings {
        LanguageSettings(chosen: pair ?? toChinese(.english), engine: engine)
    }

    /// Recognizes English, Japanese, and Korean. Packs: English and Japanese into
    /// Simplified Chinese installed, Korean into it downloadable. The model
    /// knows English, Japanese, and Simplified Chinese.
    private var device: LanguageSupport {
        LanguageSupport(
            recognizable: [.english, .japanese, .korean],
            packs: [
                toChinese(.english): .installed,
                toChinese(.japanese): .installed,
                toChinese(.korean): .downloadable,
            ],
            modelLanguages: [.english, .japanese, .simplifiedChinese]
        )
    }

    // MARK: Before the device has answered

    @Test("Before the device has answered, the choice stands and is the only thing offered")
    func beforeAnAnswer() {
        let settings = settings(LanguagePair(spoken: .french, target: .german), engine: .appleIntelligence)
        #expect(settings.pair == LanguagePair(spoken: .french, target: .german))
        #expect(settings.engine == .appleIntelligence)
        #expect(settings.spokenChoices == [.french])
        #expect(settings.targetChoices == [.german])
        #expect(settings.engineChoices == [.appleIntelligence])
        #expect(!settings.needsLanguagePack)
    }

    // MARK: What a session will use

    @Test("A choice the device cannot do gives way, and the choice itself is kept")
    func choiceIsKept() {
        var settings = settings(toChinese(.french))
        let asked = settings.beginAsking()
        settings.take(device, asked: asked)
        #expect(settings.pair == toChinese(.english))
        #expect(settings.chosen == toChinese(.french))

        // The device learns French: the choice comes back by itself.
        var better = device
        better.recognizable.insert(.french)
        better.packs[toChinese(.french)] = .installed
        settings.take(better, asked: settings.beginAsking())
        #expect(settings.pair == toChinese(.french))
    }

    @Test("The engine in use is the chosen one when it can translate the pair, else the other")
    func engineInUse() {
        var settings = settings(toChinese(.korean), engine: .appleIntelligence)
        settings.take(device, asked: settings.beginAsking())
        #expect(settings.engine == .languagePack)
        #expect(settings.chosenEngine == .appleIntelligence)
        #expect(settings.engineChoices == [.languagePack])
        settings.choose(spoken: .english)
        #expect(settings.engine == .appleIntelligence)
        #expect(settings.engineChoices == [.languagePack, .appleIntelligence])
    }

    @Test("The choices offered always include what is in use")
    func choicesIncludeTheCurrent() {
        var settings = settings(toChinese(.korean))
        settings.take(device, asked: settings.beginAsking())
        #expect(settings.spokenChoices == [.english, .japanese, .korean])
        #expect(settings.targetChoices.contains(.simplifiedChinese))
    }

    @Test("A language pack is needed when the pack engine is in use and its pack is not downloaded")
    func needsLanguagePack() {
        var settings = settings(toChinese(.korean))
        settings.take(device, asked: settings.beginAsking())
        #expect(settings.needsLanguagePack)
        settings.choose(spoken: .english)
        #expect(!settings.needsLanguagePack)
    }

    // MARK: Choosing

    @Test("Choosing a side keeps that side when the device cannot do the pair")
    func choosingKeepsTheSide() {
        // Japanese can also go into English here, by a pack.
        var device = device
        device.packs[LanguagePair(spoken: .japanese, target: .english)] = .installed
        var settings = settings(toChinese(.korean))
        settings.take(device, asked: settings.beginAsking())

        // Korean cannot go into English: the target was just chosen, so the
        // spoken language gives way.
        settings.choose(target: .english)
        #expect(settings.pair == LanguagePair(spoken: .japanese, target: .english))

        // Korean again: now the spoken language was just chosen, so the target
        // gives way.
        settings.choose(spoken: .korean)
        #expect(settings.pair == toChinese(.korean))
    }

    @Test("Choosing swaps from the pair in use, not from a choice that gave way")
    func choosingStartsFromThePairInUse() {
        var settings = settings(toChinese(.french))
        settings.take(device, asked: settings.beginAsking())
        #expect(settings.pair == toChinese(.english))
        // Simplified Chinese is the target in use; English, in use as spoken, becomes the target.
        var chinese = device
        chinese.recognizable.insert(.simplifiedChinese)
        chinese.packs[LanguagePair(spoken: .simplifiedChinese, target: .english)] = .installed
        settings.take(chinese, asked: settings.beginAsking())
        settings.choose(spoken: .simplifiedChinese)
        #expect(settings.pair == LanguagePair(spoken: .simplifiedChinese, target: .english))
    }

    // MARK: Answers out of order

    @Test("An answer to an earlier question does not replace the answer to a later one")
    func staleAnswer() {
        var settings = settings(toChinese(.korean))
        let first = settings.beginAsking()
        let second = settings.beginAsking()
        var downloaded = device
        downloaded.packs[toChinese(.korean)] = .installed

        let taken1 = settings.take(downloaded, asked: second)
        #expect(taken1)
        #expect(!settings.needsLanguagePack)
        // The first question was asked before the download and answers late.
        let taken2 = settings.take(device, asked: first)
        #expect(!taken2)
        #expect(!settings.needsLanguagePack)
        #expect(settings.support == downloaded)
    }

    @Test("An answer to an earlier question is used while the later one is still out")
    func earlierAnswerWhileWaiting() {
        var settings = settings(toChinese(.korean))
        let first = settings.beginAsking()
        let second = settings.beginAsking()
        let taken3 = settings.take(device, asked: first)
        #expect(taken3)
        #expect(settings.needsLanguagePack)
        var downloaded = device
        downloaded.packs[toChinese(.korean)] = .installed
        let taken4 = settings.take(downloaded, asked: second)
        #expect(taken4)
        #expect(!settings.needsLanguagePack)
    }

    @Test("A late answer does not undo the side the user chose meanwhile")
    func answerAfterChoosing() {
        // The answer on its way knows only two pairs: English into Simplified
        // Chinese, and Japanese into French.
        let narrow = LanguageSupport(
            recognizable: [.english, .japanese],
            packs: [
                toChinese(.english): .installed,
                LanguagePair(spoken: .japanese, target: .french): .installed,
            ]
        )
        var settings = settings(toChinese(.english))
        let asked = settings.beginAsking()
        settings.choose(target: .french)
        settings.take(narrow, asked: asked)
        // French was just chosen, so it stays and the spoken language gives way.
        #expect(settings.pair == LanguagePair(spoken: .japanese, target: .french))
        #expect(settings.chosen == LanguagePair(spoken: .english, target: .french))
    }

    // MARK: While a session runs

    @Test("While a session runs the pair stays, whatever is chosen or answered")
    func locked() {
        var settings = settings(toChinese(.korean))
        settings.take(device, asked: settings.beginAsking())
        settings.lock()
        #expect(settings.isLocked)
        settings.choose(spoken: .english)
        settings.choose(target: .english)
        #expect(settings.pair == toChinese(.korean))
        #expect(settings.chosen == toChinese(.korean))

        var worse = device
        worse.recognizable.remove(.korean)
        settings.take(worse, asked: settings.beginAsking())
        #expect(settings.pair == toChinese(.korean))

        // After the session the pair is settled again.
        settings.unlock()
        #expect(settings.pair == toChinese(.english))
    }

    @Test("A session started before the device answered keeps its pair, and the next one does not")
    func lockedBeforeAnAnswer() {
        var settings = settings(toChinese(.french))
        settings.lock()
        settings.take(device, asked: settings.beginAsking())
        #expect(settings.pair == toChinese(.french))
        settings.unlock()
        #expect(settings.pair == toChinese(.english))
    }

    // MARK: Preparing the translator again

    @Test("A translator is prepared again when the engine in use is no longer the one it was prepared with")
    func prepareAgainForAnotherEngine() {
        // Started before the device answered, with the model chosen.
        var settings = settings(toChinese(.korean), engine: .appleIntelligence)
        settings.lock()
        let prepared = settings.preparation
        #expect(prepared.engine == .appleIntelligence)
        #expect(!settings.needsPreparingAgain(after: prepared, isReady: false))
        // The answer: the model cannot do Korean, the pack engine is in use.
        settings.take(device, asked: settings.beginAsking())
        #expect(settings.engine == .languagePack)
        #expect(settings.needsPreparingAgain(after: prepared, isReady: false))
        #expect(settings.needsPreparingAgain(after: prepared, isReady: true))
        #expect(!settings.needsPreparingAgain(after: settings.preparation, isReady: true))
    }

    @Test("Choosing the engine that is already in use prepares nothing again")
    func prepareAgainNotForTheSameEngine() {
        var settings = settings(toChinese(.korean), engine: .appleIntelligence)
        settings.take(device, asked: settings.beginAsking())
        settings.lock()
        let prepared = settings.preparation
        #expect(prepared.engine == .languagePack)
        settings.chosenEngine = .languagePack
        #expect(!settings.needsPreparingAgain(after: prepared, isReady: true))
    }

    @Test("A translator that is not ready is prepared again once its language pack has arrived")
    func prepareAgainWhenThePackArrives() {
        var settings = settings(toChinese(.korean))
        settings.take(device, asked: settings.beginAsking())
        settings.lock()
        let prepared = settings.preparation
        #expect(prepared.pack == .downloadable)

        var downloaded = device
        downloaded.packs[toChinese(.korean)] = .installed
        settings.take(downloaded, asked: settings.beginAsking())
        // Still preparing, or failed for want of the pack: either way, again.
        #expect(settings.needsPreparingAgain(after: prepared, isReady: false))
        // One that got ready meanwhile is left alone.
        #expect(!settings.needsPreparingAgain(after: prepared, isReady: true))
        // And one prepared after the pack arrived is not prepared a second time.
        #expect(!settings.needsPreparingAgain(after: settings.preparation, isReady: false))
    }

    @Test("A translator prepared before the device answered is prepared again when the pack turns out installed and it is not ready")
    func prepareAgainAfterTheFirstAnswer() {
        var settings = settings(toChinese(.english))
        settings.lock()
        let prepared = settings.preparation
        #expect(prepared.pack == nil)
        settings.take(device, asked: settings.beginAsking())
        #expect(settings.needsPreparingAgain(after: prepared, isReady: false))
        #expect(!settings.needsPreparingAgain(after: prepared, isReady: true))
    }
}

@Suite("SpeechModelBudget")
struct SpeechModelBudgetTests {
    @Test("Nothing is released while there is room")
    func room() {
        #expect(SpeechModelBudget.toRelease(reserved: ["en-US", "ja-JP"], wanted: "ko-KR", maximum: 5) == [])
        #expect(SpeechModelBudget.toRelease(reserved: [], wanted: "ko-KR", maximum: 5) == [])
    }

    @Test("Nothing is released for a model that is already reserved")
    func alreadyReserved() {
        let reserved = ["en-US", "ja-JP", "zh-CN", "ko-KR", "es-ES"]
        #expect(SpeechModelBudget.toRelease(reserved: reserved, wanted: "ko-KR", maximum: 5) == [])
    }

    @Test("When the reservations are used up, one is released to make room")
    func full() {
        let reserved = ["en-US", "ja-JP", "zh-CN", "ko-KR", "es-ES"]
        #expect(SpeechModelBudget.toRelease(reserved: reserved, wanted: "fr-FR", maximum: 5) == ["en-US"])
    }

    @Test("More are released when more than the limit are reserved")
    func overFull() {
        let reserved = ["en-US", "ja-JP", "zh-CN", "ko-KR", "es-ES", "de-DE"]
        #expect(SpeechModelBudget.toRelease(reserved: reserved, wanted: "fr-FR", maximum: 5) == ["en-US", "ja-JP"])
    }

    @Test("A limit below one is treated as one")
    func tinyLimit() {
        #expect(SpeechModelBudget.toRelease(reserved: ["en-US"], wanted: "fr-FR", maximum: 0) == ["en-US"])
    }
}

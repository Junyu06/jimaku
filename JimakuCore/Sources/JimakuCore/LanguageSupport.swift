/// Whether the system has the language pack that translates a pair.
public enum LanguagePackStatus: Equatable, Sendable {
    case installed
    /// The system offers it, and it has not been downloaded.
    case downloadable
    case unsupported
}

/// Why an engine cannot translate a pair on this device.
public enum EngineObstacle: Equatable, Sendable {
    /// The device can never run the on-device language model.
    case deviceCannotRunModel
    /// The language model does not work in this language.
    case modelLacksLanguage(CaptionLanguage)
    /// The system has no language pack for the pair.
    case noLanguagePack
    /// Both sides are forms of one language, which nothing translates.
    case sameLanguage
}

/// What this device can do with the languages, as the system reported it.
///
/// The app asks the system and fills this in; the rules for what to offer are
/// here.
public struct LanguageSupport: Equatable, Sendable {
    /// The languages the speech recognizer knows.
    public var recognizable: Set<CaptionLanguage>
    /// The language pack for each pair the system reported on.
    public var packs: [LanguagePair: LanguagePackStatus]
    /// The languages the on-device language model works in. Empty when the
    /// device has no such model.
    public var modelLanguages: Set<CaptionLanguage>
    /// False on a device that can never run the on-device language model. One
    /// where the model is switched off or still being downloaded can run it.
    public var deviceRunsModel: Bool

    public init(
        recognizable: Set<CaptionLanguage> = [],
        packs: [LanguagePair: LanguagePackStatus] = [:],
        modelLanguages: Set<CaptionLanguage> = [],
        deviceRunsModel: Bool = true
    ) {
        self.recognizable = recognizable
        self.packs = packs
        self.modelLanguages = modelLanguages
        self.deviceRunsModel = deviceRunsModel
    }

    public func packStatus(for pair: LanguagePair) -> LanguagePackStatus {
        packs[pair] ?? .unsupported
    }

    /// The engines that can translate `pair`, language packs first. A pack that
    /// still has to be downloaded counts: the app offers the download.
    public func engines(for pair: LanguagePair) -> [TranslationEngine] {
        [.languagePack, .appleIntelligence].filter { obstacle(to: $0, for: pair) == nil }
    }

    /// What keeps `engine` from translating `pair`, or nil when it can. The
    /// settings list an engine that cannot be used with this as the reason.
    public func obstacle(to engine: TranslationEngine, for pair: LanguagePair) -> EngineObstacle? {
        guard pair.isTranslatable else { return .sameLanguage }
        switch engine {
        case .languagePack:
            return packStatus(for: pair) == .unsupported ? .noLanguagePack : nil
        case .appleIntelligence:
            guard deviceRunsModel else { return .deviceCannotRunModel }
            // The spoken language first: it is the one the user picked the
            // video by.
            return [pair.spoken, pair.target].first { !modelLanguages.contains($0) }.map { .modelLacksLanguage($0) }
        }
    }

    /// Whether a session can run with `pair`: the device recognizes the spoken
    /// language and some engine translates it into the target.
    public func canCaption(_ pair: LanguagePair) -> Bool {
        recognizable.contains(pair.spoken) && !engines(for: pair).isEmpty
    }

    /// The engine to translate `pair` with: the preferred one if it can, else
    /// the one that can. When neither can, the preference stands.
    public func engine(preferring preferred: TranslationEngine, for pair: LanguagePair) -> TranslationEngine {
        let usable = engines(for: pair)
        return usable.contains(preferred) ? preferred : usable.first ?? preferred
    }

    /// The spoken languages to offer: those the device recognizes and some
    /// engine can translate into something. The target does not narrow the
    /// list, so choosing a language of the target's family swaps the two.
    public var spokenChoices: [CaptionLanguage] {
        CaptionLanguage.all.filter { !targets(for: $0).isEmpty }
    }

    /// The targets to offer: those some spoken language can be translated into.
    public var targetChoices: [CaptionLanguage] {
        CaptionLanguage.all.filter { !spoken(for: $0).isEmpty }
    }

    /// One of the two languages of a pair.
    public enum Side: Equatable, Sendable {
        case spoken
        case target
    }

    /// `pair`, or the nearest pair this device can do. The side to keep is the
    /// one the user just chose: the other one gives way first, to `other` if
    /// the device can do that, else to the first language it can. A side the
    /// device cannot do at all gives way too, and a device that reports nothing
    /// leaves the pair as it is.
    public func settled(
        _ pair: LanguagePair,
        keeping side: Side,
        preferring other: CaptionLanguage? = nil
    ) -> LanguagePair {
        guard !canCaption(pair) else { return pair }
        func pick(_ choices: [CaptionLanguage]) -> CaptionLanguage? {
            other.flatMap { choices.contains($0) ? $0 : nil } ?? choices.first
        }
        let withSpoken = pick(targets(for: pair.spoken)).map { LanguagePair(spoken: pair.spoken, target: $0) }
        let withTarget = pick(spoken(for: pair.target)).map { LanguagePair(spoken: $0, target: pair.target) }
        let any = spokenChoices.first.flatMap { spoken in
            targets(for: spoken).first.map { LanguagePair(spoken: spoken, target: $0) }
        }
        switch side {
        case .spoken: return withSpoken ?? withTarget ?? any ?? pair
        case .target: return withTarget ?? withSpoken ?? any ?? pair
        }
    }

    /// What `spoken` can be translated into, if the device recognizes it.
    private func targets(for spoken: CaptionLanguage) -> [CaptionLanguage] {
        guard recognizable.contains(spoken) else { return [] }
        return CaptionLanguage.all.filter { !engines(for: LanguagePair(spoken: spoken, target: $0)).isEmpty }
    }

    /// The recognized languages that can be translated into `target`.
    private func spoken(for target: CaptionLanguage) -> [CaptionLanguage] {
        CaptionLanguage.all.filter {
            recognizable.contains($0) && !engines(for: LanguagePair(spoken: $0, target: target)).isEmpty
        }
    }
}

/// Whether the system has the language pack that translates a pair.
public enum LanguagePackStatus: Equatable, Sendable {
    case installed
    /// The system offers it, and it has not been downloaded.
    case downloadable
    case unsupported
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

    public init(
        recognizable: Set<CaptionLanguage> = [],
        packs: [LanguagePair: LanguagePackStatus] = [:],
        modelLanguages: Set<CaptionLanguage> = []
    ) {
        self.recognizable = recognizable
        self.packs = packs
        self.modelLanguages = modelLanguages
    }

    public func packStatus(for pair: LanguagePair) -> LanguagePackStatus {
        packs[pair] ?? .unsupported
    }

    /// The engines that can translate `pair`, language packs first. A pack that
    /// still has to be downloaded counts: the app offers the download.
    public func engines(for pair: LanguagePair) -> [TranslationEngine] {
        guard pair.isTranslatable else { return [] }
        var engines: [TranslationEngine] = []
        if packStatus(for: pair) != .unsupported { engines.append(.languagePack) }
        if modelLanguages.contains(pair.spoken), modelLanguages.contains(pair.target) {
            engines.append(.appleIntelligence)
        }
        return engines
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
    /// one the user just chose: the other one gives way first. A side the device
    /// cannot do at all gives way too, and a device that reports nothing leaves
    /// the pair as it is.
    public func settled(_ pair: LanguagePair, keeping side: Side) -> LanguagePair {
        guard !canCaption(pair) else { return pair }
        let withSpoken = targets(for: pair.spoken).first.map { LanguagePair(spoken: pair.spoken, target: $0) }
        let withTarget = spoken(for: pair.target).first.map { LanguagePair(spoken: $0, target: pair.target) }
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

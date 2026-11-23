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

    /// The engine to translate `pair` with: the preferred one if it can, else
    /// the one that can. When neither can, the preference stands.
    public func engine(preferring preferred: TranslationEngine, for pair: LanguagePair) -> TranslationEngine {
        let usable = engines(for: pair)
        return usable.contains(preferred) ? preferred : usable.first ?? preferred
    }

    /// The spoken languages to offer for a target: those the device recognizes
    /// and some engine can translate into it.
    public func spokenChoices(for target: CaptionLanguage) -> [CaptionLanguage] {
        CaptionLanguage.all.filter { spoken in
            recognizable.contains(spoken) && !engines(for: LanguagePair(spoken: spoken, target: target)).isEmpty
        }
    }

    /// The targets to offer: those some spoken language can be translated into.
    public var targetChoices: [CaptionLanguage] {
        CaptionLanguage.all.filter { !spokenChoices(for: $0).isEmpty }
    }

    /// `pair`, or the nearest pair this device can do: the same spoken language
    /// into another target, else another spoken language. A device that reports
    /// nothing leaves the pair as it is.
    public func settled(_ pair: LanguagePair) -> LanguagePair {
        let targets = targetChoices
        guard let firstTarget = targets.first else { return pair }
        var pair = pair
        if !targets.contains(pair.target) {
            pair.target = targets.first { spokenChoices(for: $0).contains(pair.spoken) } ?? firstTarget
        }
        let spoken = spokenChoices(for: pair.target)
        if !spoken.contains(pair.spoken), let first = spoken.first { pair.spoken = first }
        return pair
    }
}

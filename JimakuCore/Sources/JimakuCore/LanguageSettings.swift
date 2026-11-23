/// The languages and the engine the user chose, and what a session uses given
/// what the device can do.
///
/// The choice is kept apart from what is in use. A choice the device cannot do
/// gives way while that lasts and comes back when the device can; it is never
/// overwritten by what the device reports.
public struct LanguageSettings: Equatable, Sendable {
    /// The pair the user chose. This is what gets stored.
    public private(set) var chosen: LanguagePair

    /// The engine the user chose. `engine` is the one in use.
    public var chosenEngine: TranslationEngine

    /// The side the user chose last. When the device cannot do the pair, the
    /// other side gives way first.
    public private(set) var kept: LanguageSupport.Side = .spoken

    /// What the device can do. Nil until the system has answered.
    public private(set) var support: LanguageSupport?

    /// The pair of the running session. While it is set nothing changes the pair.
    private var locked: LanguagePair?

    /// How many times the system has been asked, and which of those questions
    /// the answer in `support` belongs to.
    private var asked = 0
    private var answered = 0

    public init(chosen: LanguagePair, engine: TranslationEngine) {
        self.chosen = chosen
        self.chosenEngine = engine
    }

    // MARK: What is in use

    /// The pair a session uses: the chosen one, or the nearest the device can do.
    public var pair: LanguagePair {
        locked ?? support?.settled(chosen, keeping: kept) ?? chosen
    }

    /// The engine that translates the pair: the chosen one, or the other when
    /// the chosen one cannot.
    public var engine: TranslationEngine {
        support?.engine(preferring: chosenEngine, for: pair) ?? chosenEngine
    }

    /// The language pack for the pair. Nil until the system has answered.
    public var packStatus: LanguagePackStatus? {
        support?.packStatus(for: pair)
    }

    /// Whether the pair needs a language pack that the system offers and has
    /// not downloaded.
    public var needsLanguagePack: Bool {
        engine == .languagePack && packStatus == .downloadable
    }

    // MARK: What to offer

    /// The spoken languages to offer, with the one in use always among them.
    public var spokenChoices: [CaptionLanguage] {
        let offered = support?.spokenChoices ?? []
        return CaptionLanguage.all.filter { offered.contains($0) || $0 == pair.spoken }
    }

    /// The targets to offer, with the one in use always among them.
    public var targetChoices: [CaptionLanguage] {
        let offered = support?.targetChoices ?? []
        return CaptionLanguage.all.filter { offered.contains($0) || $0 == pair.target }
    }

    /// The engines to offer for the pair, with the one in use always among them.
    public var engineChoices: [TranslationEngine] {
        let usable = support?.engines(for: pair) ?? []
        return TranslationEngine.allCases.filter { usable.contains($0) || $0 == engine }
    }

    // MARK: Choosing

    /// Chooses the spoken language, starting from the pair in use. Choosing the
    /// target's language swaps the two. Does nothing while a session runs.
    public mutating func choose(spoken: CaptionLanguage) {
        guard locked == nil else { return }
        chosen = pair.choosing(spoken: spoken)
        kept = .spoken
    }

    /// Chooses the target, starting from the pair in use. Does nothing while a
    /// session runs.
    public mutating func choose(target: CaptionLanguage) {
        guard locked == nil else { return }
        chosen = pair.choosing(target: target)
        kept = .target
    }

    // MARK: A running session

    public var isLocked: Bool { locked != nil }

    /// Fixes the pair for a session that is starting.
    public mutating func lock() {
        locked = pair
    }

    /// The session ended: the pair follows the choice and the device again.
    public mutating func unlock() {
        locked = nil
    }

    // MARK: Asking the device

    /// Call before asking the system what it can do. Returns what to hand back
    /// with the answer.
    public mutating func beginAsking() -> Int {
        asked += 1
        return asked
    }

    /// Takes the system's answer to the question `question`. Answers can come
    /// back out of order: one to an earlier question than the answer already
    /// held is dropped. Returns whether the answer was taken.
    @discardableResult
    public mutating func take(_ support: LanguageSupport, asked question: Int) -> Bool {
        guard question > answered else { return false }
        answered = question
        self.support = support
        return true
    }

    // MARK: The session's translator

    /// What a translator was prepared with.
    public struct Preparation: Equatable, Sendable {
        public let engine: TranslationEngine
        /// The language pack for the pair as it was known then. Nil when the
        /// system had not answered yet.
        public let pack: LanguagePackStatus?
    }

    /// What a translator prepared now is prepared with.
    public var preparation: Preparation {
        Preparation(engine: engine, pack: packStatus)
    }

    /// Whether the translator of the running session has to be prepared again.
    ///
    /// It has to when the engine in use is no longer the one it was prepared
    /// with. And it has to when it uses language packs, is not ready, and the
    /// pack is installed now and was not known to be when it was prepared: it
    /// is then either failing for want of the pack or still being prepared by a
    /// request that may have been told the pack was missing.
    public func needsPreparingAgain(after earlier: Preparation, isReady: Bool) -> Bool {
        if engine != earlier.engine { return true }
        return engine == .languagePack && !isReady && packStatus == .installed && earlier.pack != .installed
    }
}

/// The system keeps the speech models of only so many locales for an app. A
/// model beyond that is not downloaded until one is given up.
public enum SpeechModelBudget {
    /// The locales to give up so that `wanted` can be kept: none while there is
    /// room or when it is kept already, else as many of the first ones as make
    /// room.
    public static func toRelease(reserved: [String], wanted: String, maximum: Int) -> [String] {
        guard !reserved.contains(wanted) else { return [] }
        let excess = reserved.count + 1 - max(maximum, 1)
        return excess > 0 ? Array(reserved.prefix(excess)) : []
    }
}

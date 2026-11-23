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
    public private(set) var chosenEngine: TranslationEngine

    /// The side the user chose last. When the device cannot do the pair, the
    /// other side gives way first. Stored with the choice.
    public private(set) var kept: LanguageSupport.Side

    /// What was shown on the other side when the user last chose. When that
    /// side has to give way, it goes back to this if the device can do it, so
    /// choosing one side does not change the other on screen without need.
    /// Stored with the choice, so the pair in use is the same when the app is
    /// opened again.
    public private(set) var shownBefore: CaptionLanguage?

    /// What the device can do. Nil until the system has answered.
    public private(set) var support: LanguageSupport?

    /// The pair of the running session. While it is set nothing changes the pair.
    private var locked: LanguagePair?

    /// How many times the system has been asked, and which of those questions
    /// the answer in `support` belongs to.
    private var asked = 0
    private var answered = 0

    public init(
        chosen: LanguagePair,
        engine: TranslationEngine,
        kept: LanguageSupport.Side = .spoken,
        shownBefore: CaptionLanguage? = nil
    ) {
        self.chosen = chosen
        self.chosenEngine = engine
        self.kept = kept
        self.shownBefore = shownBefore
    }

    // MARK: What is in use

    /// The pair a session uses: the chosen one, or the nearest the device can do.
    public var pair: LanguagePair {
        locked ?? support?.settled(chosen, keeping: kept, preferring: shownBefore) ?? chosen
    }

    /// Whether a session can start: the device can do the pair, or has not
    /// answered yet. A device that has answered and cannot do any pair leaves
    /// the choice as it is, and nothing to start with.
    public var canStart: Bool {
        support.map { $0.canCaption(pair) } ?? true
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

    /// The engines that can translate the pair, with the one in use always
    /// among them.
    public var engineChoices: [TranslationEngine] {
        let usable = support?.engines(for: pair) ?? []
        return TranslationEngine.allCases.filter { usable.contains($0) || $0 == engine }
    }

    /// What keeps `engine` from translating the pair in use, or nil when it
    /// can or the device has not answered yet. The settings list every engine,
    /// and one that has something in its way cannot be chosen.
    public func obstacle(to engine: TranslationEngine) -> EngineObstacle? {
        support?.obstacle(to: engine, for: pair)
    }

    /// Whether some engine can translate the pair in use, or the device has
    /// not answered yet. When none can, there is no engine in use to show.
    public var canTranslate: Bool {
        support.map { !$0.engines(for: pair).isEmpty } ?? true
    }

    /// Chooses an engine, unless something is in its way; the earlier choice
    /// then stays. It can be chosen while a session runs. Returns whether it
    /// was chosen.
    @discardableResult
    public mutating func choose(engine: TranslationEngine) -> Bool {
        guard obstacle(to: engine) == nil else { return false }
        chosenEngine = engine
        return true
    }

    // MARK: Choosing

    /// Chooses the spoken language. Choosing the language shown as the target
    /// swaps the two that are shown. Otherwise only the spoken side of the
    /// choice changes: a target that has given way stays chosen and comes back
    /// when the device can do it. One case remains where both sides change: the
    /// chosen target has given way and is of the language now chosen as
    /// spoken. It cannot stay the target, and the one shown takes its place.
    /// Does nothing while a session runs.
    public mutating func choose(spoken: CaptionLanguage) {
        guard locked == nil, let spoken = spoken.spokenForm else { return }
        let shown = pair
        if spoken.family == shown.target.family {
            chosen = shown.choosing(spoken: spoken)
        } else {
            var next = LanguagePair(spoken: spoken, target: chosen.target)
            // The chosen target is of this family and has given way to the one shown.
            if !next.isTranslatable { next.target = shown.target }
            chosen = next
        }
        kept = .spoken
        shownBefore = shown.target
    }

    /// Chooses the target, the same way.
    public mutating func choose(target: CaptionLanguage) {
        guard locked == nil else { return }
        let shown = pair
        if target.family == shown.spoken.family {
            chosen = shown.choosing(target: target)
        } else {
            var next = LanguagePair(spoken: chosen.spoken, target: target)
            if !next.isTranslatable { next.spoken = shown.spoken }
            chosen = next
        }
        kept = .target
        shownBefore = shown.spoken
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
    /// pack is installed now, if the pack was not known to be installed when
    /// it was prepared, or if preparing it failed for want of the pack whatever
    /// was known: it is then either failing for want of the pack or still being
    /// prepared by a request that may have been told the pack was missing.
    ///
    /// - Parameter missedPack: preparing it failed because the pack was missing.
    public func needsPreparingAgain(after earlier: Preparation, isReady: Bool, missedPack: Bool) -> Bool {
        if engine != earlier.engine { return true }
        guard engine == .languagePack, !isReady, packStatus == .installed else { return false }
        return earlier.pack != .installed || missedPack
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

/// Decides what goes to the translator, and when.
///
/// Recognition and the translator start at the same time, and the translator can
/// take longer. Sentences that settle meanwhile wait here instead of being lost.
/// One thing is translated at a time. Settled sentences go first, in order; if they
/// pile up, the oldest are dropped. When none is waiting, the speech still in
/// progress is translated provisionally, and again each time it has grown.
public struct TranslationPipeline: Equatable, Sendable {
    public enum Job: Equatable, Sendable {
        /// A settled sentence. Its translation is kept.
        case entry(Transcript.Entry)
        /// The unfinished end of the speech in progress. Its translation is provisional.
        case pending(String)
    }

    /// Speech in progress shorter than this, in columns, is not worth translating.
    public static let minimumPendingWidth = 4

    /// Speech in progress is translated again once it has grown by this many columns.
    public static let minimumPendingGrowth = 4

    public private(set) var readiness: CaptionPlaceholder.Readiness = .preparing

    private var backlog: TranslationBacklog
    private var isTranslating = false
    private var offeredPending = ""
    private var translatedPending = ""
    private var lastTranslationFailed = false

    public init(limit: Int = 3) {
        backlog = TranslationBacklog(limit: limit)
    }

    /// False when the translator could not be prepared, or its last translation failed. Captions then fall back to the original. It becomes
    /// true again when a translation succeeds or a translator is prepared anew.
    public var isTranslationAvailable: Bool {
        readiness != .failed && !lastTranslationFailed
    }

    /// A sentence has settled and should be translated when possible.
    public mutating func settle(_ entry: Transcript.Entry) {
        backlog.add(entry)
    }

    /// The current unfinished end of the speech in progress. Empty when there is none.
    public mutating func offerPending(_ text: String) {
        offeredPending = text
        // The clause ended. The same words spoken again later are a new clause.
        if text.isEmpty {
            translatedPending = ""
        }
    }

    /// The translator became ready, failed, or is being prepared again, for example
    /// after the user switched engines. Whatever was with the old translator is
    /// given up; what was waiting keeps waiting.
    public mutating func setReadiness(_ readiness: CaptionPlaceholder.Readiness) {
        self.readiness = readiness
        isTranslating = false
        translatedPending = ""
        lastTranslationFailed = false
    }

    /// The next thing to translate, or nil when the translator is not ready, is busy,
    /// or nothing needs translating. Call `finishCurrent()` when the translation is done.
    public mutating func takeNext() -> Job? {
        guard readiness == .ready, !isTranslating else { return nil }
        if let entry = backlog.next() {
            isTranslating = true
            return .entry(entry)
        }

        let text = offeredPending
        let width = CaptionText.width(of: text)
        guard width >= Self.minimumPendingWidth, text != translatedPending else { return nil }
        // The same clause, a little longer: wait until it has grown enough to matter.
        if !translatedPending.isEmpty, text.hasPrefix(translatedPending),
            width - CaptionText.width(of: translatedPending) < Self.minimumPendingGrowth
        {
            return nil
        }
        translatedPending = text
        isTranslating = true
        return .pending(text)
    }

    /// The current translation is done, without saying how it went.
    public mutating func finishCurrent() {
        isTranslating = false
    }

    /// The current translation is done, settled sentence or speech in progress alike.
    /// A failure makes translation unavailable until one succeeds; the speech in
    /// progress is then offered again, so translation can recover.
    public mutating func finishCurrent(succeeded: Bool) {
        isTranslating = false
        lastTranslationFailed = !succeeded
        if !succeeded {
            translatedPending = ""
        }
    }

    public mutating func reset() {
        self = TranslationPipeline(limit: backlog.limit)
    }
}

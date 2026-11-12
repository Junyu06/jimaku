/// Decides what goes to the translator, and when.
///
/// Recognition and the translator start at the same time, and the translator can
/// take longer. Speech that is kept meanwhile waits here instead of being lost.
/// One piece is translated at a time, in order; if they pile up, the oldest are
/// dropped. Speech that is still in progress is not translated.
public struct TranslationPipeline: Equatable, Sendable {
    public private(set) var readiness: CaptionPlaceholder.Readiness = .preparing

    private var backlog: TranslationBacklog
    private var isTranslating = false
    private var lastTranslationFailed = false

    public init(limit: Int = 3) {
        backlog = TranslationBacklog(limit: limit)
    }

    /// False when the translator could not be prepared, or its last translation
    /// failed. Captions then fall back to the original. It becomes true again when
    /// a translation succeeds or a translator is prepared anew.
    public var isTranslationAvailable: Bool {
        readiness != .failed && !lastTranslationFailed
    }

    /// Whether anything is waiting to be translated or being translated now.
    public var hasWork: Bool {
        isTranslating || !backlog.isEmpty
    }

    /// A piece of speech has been kept and should be translated when possible.
    public mutating func settle(_ entry: Transcript.Entry) {
        backlog.add(entry)
    }

    /// The translator became ready, failed, or is being prepared again, for example
    /// after the user switched engines. Whatever was with the old translator is
    /// given up; what was waiting keeps waiting.
    public mutating func setReadiness(_ readiness: CaptionPlaceholder.Readiness) {
        self.readiness = readiness
        isTranslating = false
        lastTranslationFailed = false
    }

    /// The next entry to translate, or nil when the translator is not ready, is
    /// busy, or nothing is waiting. Call `finishCurrent` when the translation is done.
    public mutating func takeNext() -> Transcript.Entry? {
        guard readiness == .ready, !isTranslating, let entry = backlog.next() else { return nil }
        isTranslating = true
        return entry
    }

    /// The current translation is done, without saying how it went.
    public mutating func finishCurrent() {
        isTranslating = false
    }

    /// The current translation is done. A failure makes translation unavailable
    /// until one succeeds.
    public mutating func finishCurrent(succeeded: Bool) {
        isTranslating = false
        lastTranslationFailed = !succeeded
    }

    public mutating func reset() {
        self = TranslationPipeline(limit: backlog.limit)
    }
}

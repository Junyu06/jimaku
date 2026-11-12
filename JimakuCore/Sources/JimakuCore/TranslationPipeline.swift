/// Decides which settled sentence goes to the translator, and when.
///
/// Recognition and the translator start at the same time, and the translator can
/// take longer. Sentences that settle meanwhile wait here instead of being lost.
/// One sentence is translated at a time, in order; if they pile up, the oldest are
/// dropped.
public struct TranslationPipeline: Equatable, Sendable {
    public private(set) var readiness: CaptionPlaceholder.Readiness = .preparing

    private var backlog: TranslationBacklog
    private var isTranslating = false

    public init(limit: Int = 3) {
        backlog = TranslationBacklog(limit: limit)
    }

    /// False once the translator has failed: captions then fall back to the original.
    public var isTranslationAvailable: Bool {
        readiness != .failed
    }

    /// A sentence has settled and should be translated when possible.
    public mutating func settle(_ entry: Transcript.Entry) {
        backlog.add(entry)
    }

    /// The translator became ready, failed, or is being prepared again, for example
    /// after the user switched engines. Whatever was with the old translator is
    /// given up; what was waiting keeps waiting.
    public mutating func setReadiness(_ readiness: CaptionPlaceholder.Readiness) {
        self.readiness = readiness
        isTranslating = false
    }

    /// The next sentence to translate, or nil when the translator is not ready, is
    /// busy, or nothing is waiting. Call `finishCurrent()` when its translation is done.
    public mutating func takeNext() -> Transcript.Entry? {
        guard readiness == .ready, !isTranslating, let entry = backlog.next() else { return nil }
        isTranslating = true
        return entry
    }

    public mutating func finishCurrent() {
        isTranslating = false
    }

    public mutating func reset() {
        self = TranslationPipeline(limit: backlog.limit)
    }
}

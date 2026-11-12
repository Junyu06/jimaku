/// Settled speech waiting to be translated.
///
/// Translation takes time. If speech settles faster than it can be translated, the
/// oldest waiting entries are dropped: a caption that arrives several sentences late
/// is worse than a missing one.
public struct TranslationBacklog: Equatable, Sendable {
    /// How many entries may wait at once.
    public let limit: Int

    private var waiting: [Transcript.Entry] = []

    public init(limit: Int = 3) {
        precondition(limit > 0, "limit must be positive")
        self.limit = limit
    }

    public var isEmpty: Bool { waiting.isEmpty }

    /// Adds an entry to translate. Returns the entries dropped to make room, oldest
    /// first; empty when nothing was dropped.
    @discardableResult
    public mutating func add(_ entry: Transcript.Entry) -> [Transcript.Entry] {
        waiting.append(entry)
        let overflow = max(waiting.count - limit, 0)
        let dropped = Array(waiting.prefix(overflow))
        waiting.removeFirst(overflow)
        return dropped
    }

    /// Takes the next entry to translate, oldest first.
    public mutating func next() -> Transcript.Entry? {
        waiting.isEmpty ? nil : waiting.removeFirst()
    }

    public mutating func removeAll() {
        waiting.removeAll()
    }
}

/// The language captions are translated into.
public enum TargetLanguage {
    /// Simplified Chinese.
    public static let identifier = "zh-Hans"
}

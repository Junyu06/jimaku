/// One piece of news from the speech recognizer.
public enum RecognitionUpdate: Equatable, Sendable {
    /// The recognizer's current guess for speech still in progress. It will change.
    case partial(String)
    /// The recognizer has settled on this text and will not change it.
    case final(String)
}

/// What has been said in a session, and what to show for it right now.
///
/// The recognizer first sends partial guesses that keep changing, then a final
/// version. Only final text becomes an entry, and only entries are translated:
/// translating a sentence that is still changing would make the translation flicker.
public struct Transcript: Equatable, Sendable {
    /// One settled piece of speech and, once it arrives, its translation.
    public struct Entry: Equatable, Sendable, Identifiable {
        public let id: Int
        public var original: String
        public var translation: String?

        public init(id: Int, original: String, translation: String?) {
            self.id = id
            self.original = original
            self.translation = translation
        }
    }

    /// Columns available on the original row before its beginning is cut.
    public static let originalRowWidth = 84

    /// Settled speech, oldest first.
    public private(set) var entries: [Entry] = []

    /// The recognizer's current guess for speech in progress.
    public private(set) var pending = ""

    public init() {}

    /// Takes in a recognizer update. Returns the new entry when the update settled a
    /// piece of speech, so the caller can send it for translation.
    @discardableResult
    public mutating func apply(_ update: RecognitionUpdate) -> Entry? {
        switch update {
        case .partial(let text):
            pending = text
            return nil
        case .final(let text):
            pending = ""
            let settled = text.trimmed
            guard !settled.isEmpty else { return nil }
            let entry = Entry(id: entries.count, original: settled, translation: nil)
            entries.append(entry)
            return entry
        }
    }

    public mutating func setTranslation(_ translation: String, for id: Int) {
        let text = translation.trimmed
        guard !text.isEmpty, let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].translation = text
    }

    public mutating func reset() {
        self = Transcript()
    }

    /// What the caption window should show now.
    ///
    /// The original row follows the speaker: the guess in progress if there is one,
    /// otherwise the last settled piece. The translation row shows the newest
    /// translation available, which stays up while the next sentence is spoken so
    /// there is time to read it.
    public var currentLines: CaptionLines {
        let speaking = pending.trimmed
        let original = speaking.isEmpty ? (entries.last?.original ?? "") : speaking
        let translation = entries.last(where: { $0.translation != nil })?.translation ?? ""
        return CaptionLines(
            original: CaptionText.tail(of: original, width: Self.originalRowWidth),
            translation: translation
        )
    }
}

/// One piece of news from the speech recognizer.
public enum RecognitionUpdate: Equatable, Sendable {
    /// The recognizer's current guess for all speech it has not finalized yet. It
    /// replaces the previous guess and will change again.
    case partial(String)
    /// The recognizer has settled on this text for that same stretch of speech.
    case final(String)
}

/// What has been said in a session, and what to show for it right now.
///
/// The recognizer sends guesses that keep changing and, eventually, a final version.
/// With fast continuous speech "eventually" can be ten seconds or more, far too late
/// for captions. So a sentence settles as soon as it finishes inside a guess, and is
/// translated then. The unfinished rest is translated provisionally while it grows.
///
/// Both caption rows run on like a ticker: settled sentences followed by the speech
/// in progress, showing their end.
public struct Transcript: Equatable, Sendable {
    /// One settled sentence and, once it arrives, its translation.
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
    public static let originalRowWidth = 64

    /// Columns available on the translation row before its beginning is cut.
    public static let translationRowWidth = 48

    /// How many settled sentences can appear on a row before the speech in progress.
    private static let recentEntryCount = 6

    /// Settled sentences, oldest first.
    public private(set) var entries: [Entry] = []

    /// The unfinished end of the speech in progress.
    public private(set) var pending = ""

    /// A provisional translation of `pending`, or of an earlier, shorter version of it.
    public private(set) var pendingTranslation: String?

    /// The text `pendingTranslation` was made from.
    private var pendingTranslationSource: String?

    /// How many characters of the recognizer's current stretch of speech have settled.
    ///
    /// The recognizer may rewrite text it already reported, moving or removing
    /// sentence boundaries. Counting characters rather than sentences keeps the
    /// settled part and the rest apart even then: what settled stays as it was, and
    /// nothing after it is lost or settled twice.
    private var consumedInStretch = 0

    public init() {}

    /// Takes in a recognizer update. Returns the sentences it settled, oldest first,
    /// so the caller can send them for translation.
    @discardableResult
    public mutating func apply(_ update: RecognitionUpdate) -> [Entry] {
        switch update {
        case .partial(let text):
            let (tail, offset) = unsettledTail(of: text)
            let split = CaptionText.sentences(in: tail)
            let settled = settle(split.complete)
            if split.consumed > 0 {
                consumedInStretch = offset + split.consumed
            }
            setPending(split.remainder)
            return settled
        case .final(let text):
            // In a final result the unfinished rest is finished too.
            let (tail, _) = unsettledTail(of: text)
            let split = CaptionText.sentences(in: tail)
            let settled = settle(split.remainder.isEmpty ? split.complete : split.complete + [split.remainder])
            consumedInStretch = 0
            setPending("")
            return settled
        }
    }

    /// The part of the stretch's text that has not settled yet, and where it starts.
    private func unsettledTail(of text: String) -> (tail: String, offset: Int) {
        let characters = Array(text)
        guard characters.count > consumedInStretch else { return ("", characters.count) }
        // If a rewrite moved the settled point into the middle of a word, start at
        // the beginning of that word rather than show half of it.
        var cut = consumedInStretch
        while cut > 0, CaptionText.isWordCharacter(characters[cut - 1]), CaptionText.isWordCharacter(characters[cut]) {
            cut -= 1
        }
        return (String(characters[cut...]), cut)
    }

    public mutating func setTranslation(_ translation: String, for id: Int) {
        let text = translation.trimmed
        guard !text.isEmpty, let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].translation = text
    }

    /// Offers a provisional translation made from `source`. It is kept only if the
    /// speech in progress still begins with that text.
    public mutating func setPendingTranslation(_ translation: String, of source: String) {
        let text = translation.trimmed
        guard !text.isEmpty, !source.isEmpty, pending.hasPrefix(source) else { return }
        pendingTranslation = text
        pendingTranslationSource = source
    }

    public mutating func reset() {
        self = Transcript()
    }

    /// What the caption window should show now: the latest settled sentences followed
    /// by the speech in progress, each row cut to its end.
    public var currentLines: CaptionLines {
        let recent = entries.suffix(Self.recentEntryCount)
        let original = Self.runOn(recent.map(\.original) + [pending])
        let translation = Self.runOn(recent.compactMap(\.translation) + [pendingTranslation ?? ""])
        return CaptionLines(
            original: CaptionText.tail(of: original, width: Self.originalRowWidth),
            translation: CaptionText.tail(of: translation, width: Self.translationRowWidth)
        )
    }

    private mutating func settle(_ sentences: some Sequence<String>) -> [Entry] {
        var settled: [Entry] = []
        for sentence in sentences {
            let text = sentence.trimmed
            guard !text.isEmpty else { continue }
            let entry = Entry(id: entries.count, original: text, translation: nil)
            entries.append(entry)
            settled.append(entry)
        }
        return settled
    }

    private mutating func setPending(_ text: String) {
        pending = text
        // A provisional translation survives only while the clause it came from is
        // still the beginning of the speech in progress.
        if let source = pendingTranslationSource, !text.hasPrefix(source) {
            pendingTranslation = nil
            pendingTranslationSource = nil
        }
    }

    /// Joins pieces into running text. A space goes between two pieces only where
    /// both sides are narrow characters, so English gets spaces and Japanese or
    /// Chinese does not.
    private static func runOn(_ pieces: [String]) -> String {
        var text = ""
        for piece in pieces.map(\.trimmed) where !piece.isEmpty {
            if let last = text.last, let first = piece.first,
                CaptionText.width(of: String(last)) == 1, CaptionText.width(of: String(first)) == 1
            {
                text += " "
            }
            text += piece
        }
        return text
    }
}

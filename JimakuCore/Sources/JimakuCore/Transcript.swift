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

    /// The beginning of the recognizer's current stretch of speech that has settled,
    /// as it read in the latest guess.
    ///
    /// The recognizer may rewrite text it already reported, moving or removing
    /// sentence boundaries or changing the length of what came before them. So the
    /// settled part is found again in every new guess rather than counted: first as
    /// an exact beginning, otherwise by looking for the clause that was still in
    /// progress. What settled stays as it was; what follows is neither lost nor
    /// settled twice.
    private var settledPrefix = ""

    public init() {}

    /// Takes in a recognizer update. Returns the sentences it settled, oldest first,
    /// so the caller can send them for translation.
    @discardableResult
    public mutating func apply(_ update: RecognitionUpdate) -> [Entry] {
        switch update {
        case .partial(let text):
            let characters = Array(text)
            guard let cut = settledBoundary(in: characters) else {
                // The guess shrank to within what has already settled.
                setPending("")
                return []
            }
            let split = CaptionText.sentences(in: String(characters[cut...]))
            let settled = settle(split.complete)
            settledPrefix = String(characters[..<(cut + split.consumed)])
            setPending(split.remainder)
            return settled
        case .final(let text):
            // In a final result the unfinished rest is finished too.
            let characters = Array(text)
            let cut = settledBoundary(in: characters) ?? characters.count
            let split = CaptionText.sentences(in: String(characters[cut...]))
            let settled = settle(split.remainder.isEmpty ? split.complete : split.complete + [split.remainder])
            settledPrefix = ""
            setPending("")
            return settled
        }
    }

    /// Where the unsettled part of the stretch begins in a new guess. Nil when the
    /// guess does not reach past what has settled.
    private func settledBoundary(in characters: [Character]) -> Int? {
        let settled = Array(settledPrefix)
        if settled.isEmpty { return 0 }

        // The usual case: the guess still begins with what settled.
        if characters.count >= settled.count, characters.starts(with: settled) {
            return settled.count
        }
        // The guess is shorter than, and part of, what settled.
        if settled.starts(with: characters) { return nil }

        // The settled part was rewritten. Look for the clause that was in progress;
        // if it appears more than once, take the place nearest to where it was.
        let anchor = Array(pending.prefix(12))
        if !anchor.isEmpty, characters.count >= anchor.count {
            var best: Int?
            for start in 0...(characters.count - anchor.count)
            where characters[start..<(start + anchor.count)].elementsEqual(anchor) {
                if best == nil || abs(start - settled.count) < abs(best! - settled.count) {
                    best = start
                }
            }
            if let best { return best }
        }

        // Nothing to hold on to: keep the same position, moved to a word start.
        guard characters.count > settled.count else { return nil }
        var cut = settled.count
        while cut > 0, CaptionText.isWordCharacter(characters[cut - 1]), CaptionText.isWordCharacter(characters[cut]) {
            cut -= 1
        }
        return cut
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

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
/// for captions. So a sentence is handed out for translation as soon as it finishes
/// inside a guess. The unfinished rest is translated provisionally while it grows.
///
/// Until a stretch of speech is final, its sentences are exactly the sentences of
/// the recognizer's latest guess: if the recognizer rewrites one, the entry changes
/// with it and is translated again. Nothing is lost or repeated, because nothing is
/// kept that the latest guess does not say. Translations follow sentences by their
/// text, so a sentence that did not change keeps its translation.
///
/// Both caption rows run on like a ticker: sentences followed by the speech in
/// progress, showing their end.
public struct Transcript: Equatable, Sendable {
    /// One settled sentence and, once it arrives, its translation.
    public struct Entry: Equatable, Sendable, Identifiable {
        public let id: Int
        public var original: String
        public var translation: String?

        /// Which stretch of speech the sentence belongs to. A translation is only
        /// ever delivered within the stretch it was made for.
        public let stretch: Int

        /// Which appearance of these words in the stretch this is. If the recognizer
        /// drops a sentence and later says the same words again, that is a new
        /// appearance, and results of jobs for the old one do not apply to it.
        public let appearance: Int

        public init(id: Int, original: String, translation: String?, stretch: Int = 0, appearance: Int = 0) {
            self.id = id
            self.original = original
            self.translation = translation
            self.stretch = stretch
            self.appearance = appearance
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

    /// Entries before this index belong to stretches that are final. The rest
    /// belong to the stretch in progress and still follow the recognizer.
    private var finalCount = 0

    /// The number of the stretch in progress.
    private var currentStretch = 0

    /// Translations received for sentences of the stretch in progress, by text.
    private var stretchTranslations: [String: String] = [:]

    /// Sentences of the stretch in progress already handed out for translation.
    private var handedOut: Set<String> = []

    /// The appearance number of each sentence the stretch in progress says now.
    private var appearances: [String: Int] = [:]

    /// The next appearance number to give out in the stretch in progress.
    private var nextAppearance = 0

    public init() {}

    /// Takes in a recognizer update. Returns the sentences that are new or rewritten
    /// and need translating, oldest first.
    @discardableResult
    public mutating func apply(_ update: RecognitionUpdate) -> [Entry] {
        switch update {
        case .partial(let text):
            let split = CaptionText.sentences(in: text)
            return follow(split.complete, pending: split.remainder, isFinal: false)
        case .final(let text):
            // In a final result the unfinished rest is finished too.
            let split = CaptionText.sentences(in: text)
            let all = split.remainder.isEmpty ? split.complete : split.complete + [split.remainder]
            return follow(all, pending: "", isFinal: true)
        }
    }

    /// Sets the translation of the entry with this identifier.
    public mutating func setTranslation(_ translation: String, for id: Int) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        setTranslation(translation, for: entries[index])
    }

    /// Delivers the translation of an entry as it was when handed out. It goes to
    /// every sentence with that text in the entry's own stretch, wherever a rewrite
    /// may have moved it. If the stretch no longer has such a sentence, the
    /// translation is dropped.
    public mutating func setTranslation(_ translation: String, for entry: Entry) {
        let text = translation.trimmed
        guard !text.isEmpty else { return }
        var delivered = false
        for index in entries.indices.reversed() {
            if entries[index].stretch < entry.stretch { break }
            if entries[index].stretch == entry.stretch, entries[index].original == entry.original,
                entries[index].appearance == entry.appearance
            {
                entries[index].translation = text
                delivered = true
            }
        }
        // Remembered while the stretch is in progress, so the sentence keeps its
        // translation through later guesses.
        if delivered, entry.stretch == currentStretch {
            stretchTranslations[entry.original] = text
        }
    }

    /// The translation of an entry failed. While its stretch is in progress, the
    /// sentence is handed out again by the next update, so it can be retried.
    public mutating func translationFailed(for entry: Entry) {
        guard entry.stretch == currentStretch, appearances[entry.original] == entry.appearance else { return }
        handedOut.remove(entry.original)
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

    /// Makes the stretch in progress say exactly `sentences`, keeping translations
    /// of sentences whose text did not change.
    private mutating func follow(_ sentences: [String], pending: String, isFinal: Bool) -> [Entry] {
        let previous = Array(entries[finalCount...])
        let sentences = sentences.map(\.trimmed).filter { !$0.isEmpty }

        // Forget what was known about sentences the recognizer no longer says. If
        // one comes back, it is treated as new.
        let present = Set(sentences)
        stretchTranslations = stretchTranslations.filter { present.contains($0.key) }
        handedOut.formIntersection(present)
        appearances = appearances.filter { present.contains($0.key) }

        var updated: [Entry] = []
        var toTranslate: [Entry] = []
        for sentence in sentences {
            let offset = updated.count
            let unchanged = offset < previous.count && previous[offset].original == sentence
            let translation = (unchanged ? previous[offset].translation : nil) ?? stretchTranslations[sentence]
            if appearances[sentence] == nil {
                appearances[sentence] = nextAppearance
                nextAppearance += 1
            }
            let entry = Entry(
                id: finalCount + offset,
                original: sentence,
                translation: translation,
                stretch: currentStretch,
                appearance: appearances[sentence] ?? 0
            )
            updated.append(entry)
            if translation == nil, handedOut.insert(sentence).inserted {
                toTranslate.append(entry)
            }
        }
        entries.replaceSubrange(finalCount..., with: updated)
        setPending(pending)
        if isFinal {
            finalCount = entries.count
            currentStretch += 1
            appearances = [:]
            nextAppearance = 0
            stretchTranslations = [:]
            handedOut = []
        }
        return toTranslate
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

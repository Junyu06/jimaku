/// One piece of news from the speech recognizer.
public enum RecognitionUpdate: Equatable, Sendable {
    /// The recognizer's current guess for all speech it has not finalized yet. It
    /// replaces the previous guess and will change again.
    case partial(String)
    /// The recognizer has settled on this text for that same stretch of speech.
    case final(String)
}

/// What has been said in a session.
///
/// The recognizer sends guesses that keep changing and, eventually, a final version.
/// With fast continuous speech "eventually" can be twenty seconds or more, far too
/// late for captions. So speech is kept in pieces while it goes on: once the front
/// of the guess has stood unchanged for a moment, a sentence, a clause, or a run of
/// words is cut off it and kept as an entry.
///
/// An entry never changes after that, whatever the recognizer says later. A caption
/// that rewrites what the reader has already read cannot be followed. The price is
/// that a correction the recognizer makes late does not reach the entry.
///
/// What is kept is counted in spoken characters, not in characters: on a device the
/// recognizer keeps adding and removing punctuation inside text it reported long
/// ago, while the words stay.
///
/// The rest of the guess is the speech in progress. It still follows the
/// recognizer, and it can carry a provisional translation.
public struct Transcript: Equatable, Sendable {
    /// One kept piece of speech and, once it arrives, its translation.
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

    /// Where the speech in progress starts. A provisional translation made for one
    /// place does not apply to another.
    public struct Mark: Equatable, Sendable {
        let stretch: Int
        let spoken: Int
    }

    /// How long, in seconds, the front of a guess must stand unchanged before it is
    /// kept. The recognizer corrects its newest words in its next burst of guesses,
    /// about a second later, and rarely after that.
    public static let stability = 0.8

    /// A failed translation is retried only for the newest few entries.
    private static let retryReach = 3

    /// Kept speech, oldest first.
    public private(set) var entries: [Entry] = []

    /// The speech in progress: the part of the latest guess that is not kept yet.
    public private(set) var pending = ""

    private let rules: ChunkRules

    /// The number of the stretch in progress. It goes up with every final result.
    private var stretch = 0

    /// How many spoken characters of the stretch in progress are kept.
    private var keptSpoken = 0

    /// The spoken characters of the latest guess, and for each when it was first
    /// seen in its place with everything before it as it is now.
    private var guess: [Character] = []
    private var firstSeen: [Double] = []

    private struct Provisional: Equatable, Sendable {
        var text: String
        var mark: Mark
        /// Set when the speech it was made for has been kept: it stays on show
        /// until an entry from this one on gets its own translation.
        var bridgesFrom: Int?
    }

    private var provisional: Provisional?

    /// Entries whose translation failed and that the next update hands out again.
    private var retry: [Int] = []

    public init(rules: ChunkRules = .english) {
        self.rules = rules
    }

    /// Where the speech in progress starts now.
    public var pendingMark: Mark { Mark(stretch: stretch, spoken: keptSpoken) }

    /// The provisional translation to show after the kept translations, if any.
    public var pendingTranslation: String? {
        guard let provisional else { return nil }
        if provisional.bridgesFrom != nil { return provisional.text }
        return provisional.mark == pendingMark && !pending.isEmpty ? provisional.text : nil
    }

    /// Takes in a recognizer update that arrived at `time`, in seconds on any
    /// steady clock. Returns the entries to translate, oldest first: the ones just
    /// kept, and before them any whose translation failed and can be tried again.
    @discardableResult
    public mutating func apply(_ update: RecognitionUpdate, at time: Double) -> [Entry] {
        let before = pendingMark
        let kept: [Entry]
        switch update {
        case .partial(let text):
            let stable = noteGuess(text, at: time)
            let rest = CaptionText.dropping(spoken: keptSpoken, from: text)
            let cut = CaptionText.chunks(
                in: rest,
                stableSpoken: max(stable - keptSpoken, 0),
                isComplete: false,
                rules: rules
            )
            kept = keep(cut.chunks)
            keptSpoken += cut.spoken
            pending = cut.rest
        case .final(let text):
            let rest = CaptionText.dropping(spoken: keptSpoken, from: text)
            let cut = CaptionText.chunks(in: rest, stableSpoken: 0, isComplete: true, rules: rules)
            kept = keep(cut.chunks)
            pending = ""
            stretch += 1
            keptSpoken = 0
            guess = []
            firstSeen = []
        }

        if var current = provisional, current.bridgesFrom == nil, current.mark != pendingMark {
            if current.mark == before, let first = kept.first {
                // Its speech was just kept. Keep showing it until that entry has a
                // translation of its own, so the row does not go blank in between.
                current.bridgesFrom = first.id
                provisional = current
            } else {
                provisional = nil
            }
        }

        let again = retry.compactMap { id in entries[id].translation == nil ? entries[id] : nil }
        retry = []
        return again + kept
    }

    /// Sets the translation of the entry with this identifier.
    public mutating func setTranslation(_ translation: String, for id: Int) {
        let text = translation.trimmed
        guard !text.isEmpty, entries.indices.contains(id) else { return }
        entries[id].translation = text
        if let from = provisional?.bridgesFrom, id >= from {
            provisional = nil
        }
    }

    /// The translation of an entry failed. If the entry is recent, the next update
    /// hands it out again.
    public mutating func translationFailed(for id: Int) {
        guard entries.indices.contains(id), entries.count - id <= Self.retryReach, !retry.contains(id) else { return }
        retry.append(id)
    }

    /// Offers a provisional translation of the speech in progress as it was at
    /// `mark`. It is taken only if the speech in progress still starts there.
    public mutating func setPendingTranslation(_ translation: String, at mark: Mark) {
        let text = translation.trimmed
        guard !text.isEmpty, mark == pendingMark, !pending.isEmpty else { return }
        provisional = Provisional(text: text, mark: mark, bridgesFrom: nil)
    }

    public mutating func reset() {
        self = Transcript(rules: rules)
    }

    /// Remembers the guess and returns how many spoken characters at its front
    /// have stood unchanged for long enough.
    private mutating func noteGuess(_ text: String, at time: Double) -> Int {
        let spoken = text.filter(CaptionText.isSpoken)
        var same = 0
        for (old, new) in zip(guess, spoken) {
            guard old == new else { break }
            same += 1
        }
        guess = Array(spoken)
        firstSeen = Array(firstSeen.prefix(same)) + Array(repeating: time, count: guess.count - same)
        return firstSeen.firstIndex { time - $0 < Self.stability } ?? firstSeen.count
    }

    private mutating func keep(_ chunks: [String]) -> [Entry] {
        var kept: [Entry] = []
        for chunk in chunks {
            let entry = Entry(id: entries.count, original: chunk, translation: nil)
            entries.append(entry)
            kept.append(entry)
        }
        return kept
    }
}

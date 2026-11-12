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
/// of the guess has stood unchanged for a moment, a sentence is cut off it and kept
/// as an entry. A sentence also ends where the speaker pauses, and one that runs on
/// too long is cut at a clause.
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
/// recognizer. It is not translated until it is kept: a translation of half a
/// sentence is often wrong, most of all from Japanese, where the verb comes last,
/// and a reader who has read it is misled when the real one replaces it.
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

    /// How long, in seconds, the front of a guess must stand unchanged before it is
    /// kept. The recognizer corrects its newest words in its next burst of guesses,
    /// about a second later, and rarely after that.
    public static let stability = 0.8

    /// The speaker has paused when the recognizer reports again and its guess
    /// still says what it said `stability` seconds ago: a burst of guesses came
    /// and brought nothing. What was said so far is then kept as it is. This
    /// follows the recognizer's own pace, whatever it is.
    ///
    /// In case the recognizer reports nothing at all while the speaker is silent,
    /// a guess that has stood this many seconds is taken for a pause without a
    /// report. It has to be well above the gap between two bursts of guesses,
    /// about a second where it was measured, or every gap would look like a pause.
    public static let silence = 3.0

    /// A failed translation is retried only for the newest few entries.
    private static let retryReach = 3

    /// Kept speech, oldest first.
    public private(set) var entries: [Entry] = []

    /// The speech in progress: the part of the latest guess that is not kept yet.
    public private(set) var pending = ""

    private let rules: ChunkRules

    /// How many spoken characters of the stretch in progress are kept.
    private var keptSpoken = 0

    /// The spoken characters of the latest guess, and for each when it was first
    /// seen in its place with everything before it as it is now.
    private var guess: [Character] = []
    private var firstSeen: [Double] = []

    /// The latest guess as it was reported, and when its spoken characters last
    /// changed in any way, growing, shrinking, or being rewritten.
    private var guessText = ""
    private var lastChange = 0.0

    /// Entries whose translation failed and that the next update hands out again.
    private var retry: [Int] = []

    public init(rules: ChunkRules = .english) {
        self.rules = rules
    }

    /// Takes in a recognizer update that arrived at `time`, in seconds on any
    /// steady clock. Returns the entries to translate, oldest first: the ones just
    /// kept, and before them any whose translation failed and can be tried again.
    @discardableResult
    public mutating func apply(_ update: RecognitionUpdate, at time: Double) -> [Entry] {
        let kept: [Entry]
        switch update {
        case .partial(let text):
            kept = take(text, at: time)
        case .final(let text):
            let rest = CaptionText.dropping(spoken: keptSpoken, from: text)
            let cut = CaptionText.chunks(in: rest, stableSpoken: 0, isComplete: true, rules: rules)
            kept = keep(cut.chunks)
            pending = ""
            keptSpoken = 0
            guess = []
            firstSeen = []
            guessText = ""
        }

        let again = retry.compactMap { id in entries[id].translation == nil ? entries[id] : nil }
        retry = []
        return again + kept
    }

    /// Time has passed without an update. If the latest guess has stood for
    /// `silence` seconds, the speaker has paused and the speech in progress is kept. Returns
    /// the entries just kept; unlike `apply`, it does not hand out entries whose
    /// translation failed, so calling it often does not retry them often.
    @discardableResult
    public mutating func elapse(to time: Double) -> [Entry] {
        guard !pending.isEmpty, time - lastChange >= Self.silence else { return [] }
        return take(guessText, at: time, pauseAfter: Self.silence)
    }

    /// Takes in a guess, or the same guess again at a later time.
    ///
    /// - Parameter pauseAfter: how long the guess must have stood unchanged for
    ///   the speaker to count as paused.
    private mutating func take(_ text: String, at time: Double, pauseAfter: Double = stability) -> [Entry] {
        let stable = noteGuess(text, at: time)
        let rest = CaptionText.dropping(spoken: keptSpoken, from: text)
        let cut = CaptionText.chunks(
            in: rest,
            stableSpoken: max(stable - keptSpoken, 0),
            // Nothing has changed for a moment: the speaker has paused, so the end
            // of what was said ends a piece.
            isComplete: !guess.isEmpty && time - lastChange >= pauseAfter,
            rules: rules
        )
        let kept = keep(cut.chunks)
        keptSpoken += cut.spoken
        pending = cut.rest
        return kept
    }

    /// Sets the translation of the entry with this identifier.
    public mutating func setTranslation(_ translation: String, for id: Int) {
        let text = translation.trimmed
        guard !text.isEmpty, entries.indices.contains(id) else { return }
        entries[id].translation = text
    }

    /// The translation of an entry failed. If the entry is recent, the next update
    /// hands it out again.
    public mutating func translationFailed(for id: Int) {
        guard entries.indices.contains(id), entries.count - id <= Self.retryReach, !retry.contains(id) else { return }
        retry.append(id)
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
        if same != guess.count || same != spoken.count {
            lastChange = time
        }
        guess = Array(spoken)
        guessText = text
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

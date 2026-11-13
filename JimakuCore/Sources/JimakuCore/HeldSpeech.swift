/// Speech the recognizer has finalized on a short quiet, held until the quiet
/// has lasted long enough to be sure the speaker stopped.
///
/// Asking the recognizer early gets the words, and their translation, ready
/// before the pause is certain. But a short quiet is often only a breath in the
/// middle of a sentence. So what the recognizer returns is not passed on as
/// final yet: it is passed on as speech in progress, and what the speaker says
/// next follows it. When the pause is certain, everything held is final as one
/// piece.
///
/// Updates from the recognizer go through `take`, and what comes back is what
/// the transcript should be given.
public struct HeldSpeech: Equatable, Sendable {
    /// What is held, without a full stop at its end.
    private var body = ""
    /// The full stop taken off the end of what is held. The recognizer puts one
    /// there because it was asked to finalize; if the speaker goes on, the
    /// sentence did not end there.
    private var mark = ""
    /// The place in the audio of the last possible pause the recognizer was
    /// asked about, in seconds.
    private var asked: Double?
    /// The place in the audio up to which the speaker is known to have stopped.
    private var certain = -Double.infinity
    /// What `certain` was when the recognizer was last asked: the last certain
    /// pause before the speech that the last possible pause followed.
    private var certainWhenAsked = -Double.infinity
    /// Whether the recognizer still owes its answer to the last possible pause
    /// it was asked about.
    private var isOwedAnswer = false
    /// Whether the recognizer has reported speech it has not finalized.
    private var hasSpeechInProgress = false
    /// When to stop waiting for an owed answer, in seconds of audio. Set when
    /// a pause becomes certain while the answer is owed.
    private var due: Double?

    /// A final result answers a possible pause if it ends no later than this
    /// many seconds after it. A result the recognizer gave by itself while
    /// speech went on ends further on.
    public static let slack = 0.05

    /// A final result is the answer to the last possible pause asked about if
    /// it ends no more than this many seconds before it. On a device the
    /// recognizer's results stop up to 0.15 seconds short of the audio handed
    /// over. Two possible pauses are at least 0.22 seconds apart and an answer
    /// ends at most `slack` after its own, so an answer to an older one ends
    /// at least 0.17 seconds before the last.
    public static let reach = 0.16

    /// How long, in seconds of audio after a pause is certain, what is held
    /// waits for an answer the recognizer owes. An answer takes about 0.05
    /// seconds and has been seen to take 0.35.
    public static let patience = 0.3

    public init() {}

    /// What is held: finalized by the recognizer, not yet known to be all the
    /// speaker meant to say.
    public var text: String { body + mark }

    /// The recognizer was asked to finalize at a possible pause, at `time`
    /// seconds into the audio.
    public mutating func asked(at time: Double) {
        asked = time
        certainWhenAsked = certain
        isOwedAnswer = true
    }

    /// Takes an update from the recognizer and gives the update to pass on.
    ///
    /// A final result is held if it answers a possible pause that is not
    /// certain yet: it ends after the last certain pause and no later than the
    /// possible pause asked about. A result that ends before a pause already
    /// certain is final at once, and so is one that ends further on than what
    /// was asked about, which the recognizer gave by itself; both take what
    /// was held with them.
    ///
    /// An answer to an older possible pause, with the answer to the last one
    /// still owed, is held unless the speaker had stopped for certain between
    /// the two; held, it ends with the answer still owed.
    ///
    /// - Parameter end: where in the audio a final result ends, in seconds, if
    ///   known. A result whose place is not known is final at once.
    public mutating func take(_ update: RecognitionUpdate, endingAt end: Double?) -> RecognitionUpdate {
        switch update {
        case .partial(let guess):
            hasSpeechInProgress = !guess.isEmpty
            return .partial(Self.join(body, guess))
        case .final(let said):
            let whole = Self.join(body, said)
            if let end, let asked, end < asked - Self.reach {
                // An answer to an older possible pause. The last one asked
                // about is still owed its answer, and it was asked about
                // because there was more sound.
                hasSpeechInProgress = true
                if end > certainWhenAsked + Self.slack {
                    // No certain pause lies between this speech and what the
                    // last possible pause followed: one sentence. It waits
                    // for the answer still owed, whatever has become certain
                    // since.
                    (body, mark) = Self.withoutFullStop(whole)
                    return .partial(body)
                }
                // The speaker had stopped after it: a sentence of its own.
                body = ""
                mark = ""
                return .final(whole)
            }
            isOwedAnswer = false
            hasSpeechInProgress = false
            due = nil
            if let end, let asked, end > certain + Self.slack, end <= asked + Self.slack {
                (body, mark) = Self.withoutFullStop(whole)
                return .partial(body)
            }
            body = ""
            mark = ""
            return .final(whole)
        }
    }

    /// The pause at `time` seconds into the audio is certain. Gives what was
    /// held as a final update, if anything was.
    ///
    /// If the recognizer still owes its answer to the last possible pause,
    /// nothing is given yet. That answer ends before this pause, so it will be
    /// final at once and take what is held with it, as one piece; giving the
    /// held part alone would end the sentence in the middle. `overdue(at:)`
    /// says when to stop waiting.
    public mutating func confirm(at time: Double) -> RecognitionUpdate? {
        certain = max(certain, time)
        guard !isOwedAnswer else {
            due = time + Self.patience
            return nil
        }
        return release()
    }

    /// Gives what was held as a final update if an owed answer has not come
    /// `patience` after the pause was certain, as when the sound that was
    /// asked about was a knock and the recognizer has nothing to say. Call it
    /// as the audio goes on, with the seconds of audio so far.
    ///
    /// While the recognizer has reported speech it has not finalized, the
    /// answer is still coming and what is held goes on waiting for it.
    public mutating func overdue(at time: Double) -> RecognitionUpdate? {
        guard let due, time >= due - 1e-9, !hasSpeechInProgress else { return nil }
        self.due = nil
        isOwedAnswer = false
        return release()
    }

    private mutating func release() -> RecognitionUpdate? {
        defer {
            body = ""
            mark = ""
        }
        return body.isEmpty ? nil : .final(body + mark)
    }

    private static let fullStops: Set<Character> = ["。", "．", "｡", "."]

    private static func withoutFullStop(_ text: String) -> (String, String) {
        guard let last = text.last, fullStops.contains(last) else { return (text, "") }
        return (String(text.dropLast()), String(last))
    }

    /// A space goes between two pieces only where both sides are narrow
    /// characters.
    private static func join(_ first: String, _ second: String) -> String {
        guard let last = first.last, let next = second.first else { return first + second }
        let narrow = CaptionText.width(of: String(last)) == 1 && CaptionText.width(of: String(next)) == 1
        return first + (narrow ? " " : "") + second
    }
}

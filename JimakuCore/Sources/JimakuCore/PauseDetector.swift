import Foundation

/// Notices when a speaker stops, from how loud the audio is.
///
/// Audio counts as speech while it is loud compared with what was heard lately,
/// and as quiet otherwise. A pause is quiet that lasts long enough after speech.
/// The longer the speaker has gone on without one, the shorter a quiet moment
/// counts, so that fast speech is still told apart sentence by sentence.
///
/// Audio that never goes quiet, such as speech over music, gives no pauses.
public struct PauseDetector: Equatable, Sendable {
    /// How long quiet has to last to be a pause, in seconds.
    public static let pause = 0.3
    /// How long quiet has to last once the speaker has gone on for `longSpeech`.
    public static let pauseInLongSpeech = 0.2
    /// Speech longer than this, in seconds, is cut at a shorter pause.
    public static let longSpeech = 2.5
    /// Less loud audio than this is no speech, so a click starts nothing.
    public static let minimumSpeech = 0.1

    /// Audio is judged in steps of this many seconds.
    static let step = 0.02
    /// Quiet is anything below this share of the loudness heard lately.
    static let quietShare = 0.1
    /// Below this level audio is quiet whatever was heard before. In sample units,
    /// of 32,767 at full scale.
    static let floor = 30.0
    /// The loudness heard lately fades to half in this many seconds.
    static let halfLife = 5.0

    private let samplesPerStep: Int
    private let fade: Double

    /// The part of a step that the samples so far did not fill.
    private var sumOfSquares = 0.0
    private var count = 0

    private var loudness = 0.0
    /// Steps since the speech in progress began. Nil when no speech is in progress.
    private var stepsSinceStart: Int?
    private var loudSteps = 0
    private var quietSteps = 0

    public init(sampleRate: Int) {
        samplesPerStep = max(Int(Double(sampleRate) * Self.step), 1)
        fade = pow(0.5, Self.step / Self.halfLife)
    }

    /// Takes the next samples and says where in them a pause was found: the
    /// speaker had been speaking and had then been quiet long enough. Each place
    /// is the number of samples of this batch up to and including the one at
    /// which the quiet had lasted long enough. Usually there is none.
    public mutating func take(_ samples: [Int16]) -> [Int] {
        var pauses: [Int] = []
        for (index, sample) in samples.enumerated() {
            let value = Double(sample)
            sumOfSquares += value * value
            count += 1
            guard count == samplesPerStep else { continue }
            let level = (sumOfSquares / Double(count)).squareRoot()
            sumOfSquares = 0
            count = 0
            if take(level: level) { pauses.append(index + 1) }
        }
        return pauses
    }

    private mutating func take(level: Double) -> Bool {
        loudness = max(level, loudness * fade)
        if let steps = stepsSinceStart { stepsSinceStart = steps + 1 }
        guard level < max(Self.floor, loudness * Self.quietShare) else {
            loudSteps += 1
            quietSteps = 0
            if stepsSinceStart == nil { stepsSinceStart = 1 }
            return false
        }
        quietSteps += 1
        guard let steps = stepsSinceStart else { return false }
        let spoken = Double(steps - quietSteps) * Self.step
        let needed = spoken >= Self.longSpeech ? Self.pauseInLongSpeech : Self.pause
        guard Double(quietSteps) * Self.step >= needed - Self.step / 2 else { return false }
        let wasSpeech = Double(loudSteps) * Self.step >= Self.minimumSpeech - Self.step / 2
        stepsSinceStart = nil
        loudSteps = 0
        return wasSpeech
    }
}

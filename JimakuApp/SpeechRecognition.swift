import AVFoundation
import JimakuCore
import Speech

/// What the recognizer reported, and where in the audio it ends.
struct Heard: Sendable {
    let update: RecognitionUpdate
    /// Seconds from the first sample handed over to the end of the speech this
    /// update covers. Nil when the recognizer does not say.
    let end: Double?
}

/// Turns audio into text.
@MainActor
protocol SpeechRecognizing: AnyObject {
    /// Starts recognizing `language`. Updates arrive on the returned stream until
    /// `stop()` is called or recognition fails.
    func start(language: SourceLanguage) async throws -> AsyncThrowingStream<Heard, Error>

    /// Hands over the next samples, in the shared ring's format.
    func append(_ samples: [Int16])

    /// How much audio the recognizer has taken since it started, in seconds.
    /// The ends it reports for speech are on the same clock.
    var audioTime: Double { get }

    /// Tells the recognizer that the speaker may have paused at the end of what
    /// has been handed over. It then settles on the speech up to there and
    /// reports it as final without waiting for more.
    func speakerPaused()

    func stop() async
}

enum SpeechRecognitionError: LocalizedError {
    case unavailable
    case languageNotSupported
    case noAudioFormat

    var errorDescription: String? {
        switch self {
        case .unavailable: "这台设备上系统语音识别不可用。"
        case .languageNotSupported: "系统语音识别不支持这种语言。"
        case .noAudioFormat: "系统语音识别没有给出可用的音频格式。"
        }
    }
}

/// Speech recognition with the system's on-device model. Nothing leaves the device.
@MainActor
final class SystemSpeechRecognizer: SpeechRecognizing {
    private var analyzer: SpeechAnalyzer?
    /// What goes to the analyzer, in order: audio, and pauses at which it is
    /// asked to finalize.
    private var feed: AsyncStream<Feed>.Continuation?
    private var feedTask: Task<Void, Never>?
    private var converter: PCMConverter?
    private var resultsTask: Task<Void, Never>?
    /// How many samples have been handed over since the analyzer started. The
    /// analyzer counts its audio time from the first of them.
    private var handedOver = 0

    private enum Feed: @unchecked Sendable {
        case audio(AnalyzerInput)
        case pause(CMTime)
    }

    func start(language: SourceLanguage) async throws -> AsyncThrowingStream<Heard, Error> {
        await stop()

        guard SpeechTranscriber.isAvailable else { throw SpeechRecognitionError.unavailable }
        let wanted = Locale(identifier: language.localeIdentifier)
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: wanted) else {
            throw SpeechRecognitionError.languageNotSupported
        }
        try Task.checkCancellation()

        // Progressive transcription reports guesses while speech is in progress and
        // then a final version, which is what Transcript expects.
        let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)

        // Download the language's model if the device does not have it yet.
        if await AssetInventory.status(forModules: [transcriber]) != .installed,
            let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber])
        {
            try await request.downloadAndInstall()
        }
        try Task.checkCancellation()

        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]),
            let converter = PCMConverter(to: format)
        else { throw SpeechRecognitionError.noAudioFormat }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let (inputs, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()
        do {
            try await analyzer.start(inputSequence: inputs)
            // The session may have been stopped while this start was in progress.
            // Nothing has been published yet, so clean up what was just created.
            try Task.checkCancellation()
        } catch {
            inputContinuation.finish()
            await analyzer.cancelAndFinishNow()
            throw error
        }

        let (updates, updatesContinuation) = AsyncThrowingStream<Heard, Error>.makeStream()
        resultsTask = Task {
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    updatesContinuation.yield(
                        Heard(update: result.isFinal ? .final(text) : .partial(text), end: result.range.end.seconds))
                }
                updatesContinuation.finish()
            } catch {
                updatesContinuation.finish(throwing: error)
            }
        }

        // Audio and pauses go to the analyzer one after another, so that the
        // audio after a pause is held back until the analyzer has finalized the
        // speech before it.
        let (feeds, feedContinuation) = AsyncStream<Feed>.makeStream()
        feedTask = Task {
            for await item in feeds {
                switch item {
                case .audio(let input): inputContinuation.yield(input)
                case .pause(let time): await Self.finalize(analyzer, at: time)
                }
            }
            inputContinuation.finish()
        }

        self.analyzer = analyzer
        self.feed = feedContinuation
        self.converter = converter
        handedOver = 0
        return updates
    }

    func append(_ samples: [Int16]) {
        guard let feed, let buffer = converter?.convert(samples) else { return }
        feed.yield(.audio(AnalyzerInput(buffer: buffer)))
        handedOver += samples.count
    }

    var audioTime: Double { Double(handedOver) / Double(AudioRing.sampleRate) }

    func speakerPaused() {
        let time = CMTime(value: CMTimeValue(handedOver), timescale: CMTimeScale(AudioRing.sampleRate))
        feed?.yield(.pause(time))
    }

    /// Makes the analyzer report the speech up to `time` as final now. Left alone
    /// it finalizes continuous speech only every several seconds.
    ///
    /// The analyzer finalizes the audio it has taken in, whatever time it is
    /// given. So this waits until the analyzer has taken in the speech before
    /// the pause, which shows in its volatile range within a few hundredths of
    /// a second, and then asks it to finalize all it has. The caller holds the
    /// later audio back meanwhile, so the final result ends at the pause.
    ///
    /// The volatile range need not reach the pause itself. During a broadcast
    /// it stops about a tenth of a second short of the audio handed over and
    /// stays there until more audio comes. The audio just before a pause is
    /// quiet, so a range that reaches into that quiet has all the speech.
    ///
    /// If the analyzer has not taken the audio in after a second, it is far
    /// behind, and asking now would finalize at some earlier place or do nothing.
    /// The pause is then let go: nothing is asked, the audio goes on, and the
    /// caption ends by the other rules.
    ///
    /// The request usually returns in a few hundredths of a second, but now and
    /// then it does not return until more audio arrives. This gives up waiting
    /// after a quarter of a second and lets the audio go on; the request then
    /// finishes on its own.
    private static func finalize(_ analyzer: SpeechAnalyzer, at time: CMTime) async {
        var taken = false
        for _ in 0..<100 {
            if let end = await analyzer.volatileRange?.end.seconds,
                PauseDetector.hasSpeech(before: time.seconds, heardTo: end)
            {
                taken = true
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
            if Task.isCancelled { return }
        }
        guard taken, !Task.isCancelled else { return }
        let request = Request()
        Task {
            try? await analyzer.finalize(through: nil)
            request.isDone = true
        }
        for _ in 0..<25 where !request.isDone {
            try? await Task.sleep(for: .milliseconds(10))
            if Task.isCancelled { return }
        }
    }

    /// Whether a request to finalize has returned.
    private final class Request {
        var isDone = false
    }

    func stop() async {
        // Take everything first and only then wait, so that a start which runs
        // while this is waiting keeps the resources it creates.
        let analyzer = analyzer
        let feed = feed
        let feedTask = feedTask
        let resultsTask = resultsTask
        self.analyzer = nil
        self.feed = nil
        self.feedTask = nil
        self.converter = nil
        self.resultsTask = nil

        feed?.finish()
        feedTask?.cancel()
        resultsTask?.cancel()
        await analyzer?.cancelAndFinishNow()
    }
}

#if targetEnvironment(simulator)
    /// The simulator has no system speech model, so this replays a demo speech the
    /// way the recognizer reports speech when it is told of every pause: guesses
    /// in bursts about a second apart while a sentence is spoken, then the
    /// sentence as a final result. Simulator only.
    @MainActor
    final class ScriptedSpeechRecognizer: SpeechRecognizing {
        private var task: Task<Void, Never>?

        func start(language: SourceLanguage) async throws -> AsyncThrowingStream<Heard, Error> {
            await stop()
            let sentences = DemoCaptions.speech(in: language).map(\.original)
            let (updates, continuation) = AsyncThrowingStream<Heard, Error>.makeStream()
            task = Task {
                while !Task.isCancelled {
                    for sentence in sentences {
                        let text = Array(sentence)
                        let isSpaced = sentence.contains(" ")
                        // A burst adds about a second of speech, in a few guesses.
                        let steps: [Int] =
                            isSpaced ? Self.wordEnds(in: text) : Array(stride(from: 2, to: text.count, by: 2))
                        let stepsPerBurst = isSpaced ? 3 : 4
                        for (index, end) in steps.enumerated() {
                            continuation.yield(Heard(update: .partial(String(text[..<end])), end: nil))
                            let endsBurst = index % stepsPerBurst == stepsPerBurst - 1
                            try? await Task.sleep(for: .milliseconds(endsBurst ? 950 : 10))
                            if Task.isCancelled { break }
                        }
                        // The speaker stops, and the sentence is final soon after.
                        try? await Task.sleep(for: .milliseconds(400))
                        continuation.yield(Heard(update: .final(sentence), end: nil))
                        try? await Task.sleep(for: .milliseconds(300))
                    }
                    try? await Task.sleep(for: .milliseconds(2500))
                }
                continuation.finish()
            }
            return updates
        }

        func append(_ samples: [Int16]) {}

        var audioTime: Double { 0 }

        func speakerPaused() {}

        func stop() async {
            task?.cancel()
            task = nil
        }

        private static func wordEnds(in text: [Character]) -> [Int] {
            text.indices.filter { text[$0] == " " }
        }
    }
#endif

import AVFoundation
import JimakuCore
import Speech

/// Turns audio into text.
@MainActor
protocol SpeechRecognizing: AnyObject {
    /// Starts recognizing `language`. Updates arrive on the returned stream until
    /// `stop()` is called or recognition fails.
    func start(language: SourceLanguage) async throws -> AsyncThrowingStream<RecognitionUpdate, Error>

    /// Hands over the next samples, in the shared ring's format.
    func append(_ samples: [Int16])

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
    private var input: AsyncStream<AnalyzerInput>.Continuation?
    private var converter: PCMConverter?
    private var resultsTask: Task<Void, Never>?

    func start(language: SourceLanguage) async throws -> AsyncThrowingStream<RecognitionUpdate, Error> {
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

        let (updates, updatesContinuation) = AsyncThrowingStream<RecognitionUpdate, Error>.makeStream()
        resultsTask = Task {
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    updatesContinuation.yield(result.isFinal ? .final(text) : .partial(text))
                }
                updatesContinuation.finish()
            } catch {
                updatesContinuation.finish(throwing: error)
            }
        }

        self.analyzer = analyzer
        self.input = inputContinuation
        self.converter = converter
        return updates
    }

    func append(_ samples: [Int16]) {
        guard let input, let buffer = converter?.convert(samples) else { return }
        input.yield(AnalyzerInput(buffer: buffer))
    }

    func stop() async {
        // Take everything first and only then wait, so that a start which runs
        // while this is waiting keeps the resources it creates.
        let analyzer = analyzer
        let input = input
        let resultsTask = resultsTask
        self.analyzer = nil
        self.input = nil
        self.converter = nil
        self.resultsTask = nil

        input?.finish()
        resultsTask?.cancel()
        await analyzer?.cancelAndFinishNow()
    }
}

#if targetEnvironment(simulator)
    /// The simulator has no system speech model, so this replays a demo speech the
    /// way the recognizer was seen to report continuous speech: guesses in bursts
    /// about a second apart, ending marks in older text that come and go, and one
    /// final result at the very end. Simulator only.
    @MainActor
    final class ScriptedSpeechRecognizer: SpeechRecognizing {
        private var task: Task<Void, Never>?

        func start(language: SourceLanguage) async throws -> AsyncThrowingStream<RecognitionUpdate, Error> {
            await stop()
            let sentences = DemoCaptions.speech(in: language).map(\.original)
            let isSpaced = sentences.contains { $0.contains(" ") }
            let text = Array(sentences.joined(separator: isSpaced ? " " : ""))
            // A burst adds about a second of speech, in a few guesses.
            let steps: [Int] = isSpaced ? Self.wordEnds(in: text) : Array(stride(from: 2, through: text.count, by: 2)) + [text.count]
            let stepsPerBurst = isSpaced ? 3 : 4

            let (updates, continuation) = AsyncThrowingStream<RecognitionUpdate, Error>.makeStream()
            task = Task {
                while !Task.isCancelled {
                    for (index, end) in steps.enumerated() {
                        let burst = index / stepsPerBurst
                        continuation.yield(.partial(Self.guess(text, upTo: end, burst: burst)))
                        let endsBurst = index % stepsPerBurst == stepsPerBurst - 1
                        try? await Task.sleep(for: .milliseconds(endsBurst ? 950 : 10))
                        if Task.isCancelled { break }
                    }
                    continuation.yield(.final(String(text)))
                    try? await Task.sleep(for: .milliseconds(2500))
                }
                continuation.finish()
            }
            return updates
        }

        func append(_ samples: [Int16]) {}

        func stop() async {
            task?.cancel()
            task = nil
        }

        /// The text so far. On every other burst, sentence endings older than the
        /// newest words are left out, as the real recognizer does now and then.
        private static func guess(_ text: [Character], upTo end: Int, burst: Int) -> String {
            guard burst % 2 == 1 else { return String(text[..<end]) }
            let endings: Set<Character> = ["。", "."]
            var result = ""
            for (index, character) in text[..<end].enumerated() where !(endings.contains(character) && index < end - 6) {
                result.append(character)
            }
            return result
        }

        private static func wordEnds(in text: [Character]) -> [Int] {
            var ends = text.indices.filter { text[$0] == " " }
            ends.append(text.count)
            return ends
        }
    }
#endif

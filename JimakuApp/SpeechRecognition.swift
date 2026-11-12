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
    /// The simulator has no system speech model, so this replays scripted text the
    /// way a recognizer would: growing guesses, then a final version. Simulator only.
    @MainActor
    final class ScriptedSpeechRecognizer: SpeechRecognizing {
        private var task: Task<Void, Never>?

        func start(language: SourceLanguage) async throws -> AsyncThrowingStream<RecognitionUpdate, Error> {
            await stop()
            let sentences = DemoCaptions.script.map(\.original)
            let (updates, continuation) = AsyncThrowingStream<RecognitionUpdate, Error>.makeStream()
            task = Task {
                var index = 0
                while !Task.isCancelled {
                    let sentence = sentences[index % sentences.count]
                    let pieces =
                        sentence.contains(" ")
                        ? sentence.split(separator: " ").map { String($0) + " " }
                        : sentence.map(String.init)
                    var spoken = ""
                    for piece in pieces {
                        spoken += piece
                        continuation.yield(.partial(spoken))
                        try? await Task.sleep(for: .milliseconds(220))
                    }
                    continuation.yield(.final(sentence))
                    try? await Task.sleep(for: .milliseconds(900))
                    index += 1
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
    }
#endif

import Foundation
import JimakuCore
import Observation

/// Runs a caption session: floats the window, reads the audio the broadcast
/// extension captured, sends it to speech recognition, translates what was said,
/// and shows both.
@MainActor
@Observable
final class SessionController {
    private(set) var session = CaptionSession()

    /// A message for the user when something went wrong. Nil when all is well.
    private(set) var notice: String?

    /// What is known about the incoming audio while a session runs.
    private(set) var audioStatus: AudioMonitor.Status = .notBroadcasting

    /// What has been said in this session.
    private(set) var transcript = Transcript()

    /// The language spoken in what the user is watching.
    var language: SourceLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey) }
    }

    let window = CaptionWindow()

    private static let languageKey = "sourceLanguage"

    private let audio = AudioMonitor()
    private let recognizer: any SpeechRecognizing
    private let translator: any Translating
    private var isRecognizerReady = false
    private var isTranslatorReady = false
    private var backlog = TranslationBacklog()
    private var audioTask: Task<Void, Never>?
    private var recognitionTask: Task<Void, Never>?
    private var translationTask: Task<Void, Never>?

    init() {
        language =
            UserDefaults.standard.string(forKey: Self.languageKey).flatMap(SourceLanguage.init(rawValue:))
            ?? .english
        #if targetEnvironment(simulator)
            recognizer = ScriptedSpeechRecognizer()
            translator = ScriptedTranslator()
        #else
            recognizer = SystemSpeechRecognizer()
            translator = LanguagePackTranslator()
        #endif
    }

    func prepare() {
        window.onClosed = { [weak self] in self?.windowDidClose() }
        window.prepare()
        // Before a session, the window previews what captions look like.
        window.show(DemoCaptions.lines(at: 0))
        audioStatus = audio.status
    }

    func performPrimaryAction() {
        switch session.primaryAction {
        case .start: start()
        case .stop: stop()
        }
    }

    private func start() {
        guard window.isSupported else {
            notice = "这台设备不支持画中画，悬浮窗开不了。"
            return
        }
        notice = nil
        session.start()
        transcript.reset()
        refreshWindow()
        window.float()
        startAudio()
        startRecognition()
        prepareTranslation()
    }

    private func stop() {
        session.stop()
        endSession()
        window.close()
    }

    private func windowDidClose() {
        guard session.state == .running else { return }
        session.stop()
        endSession()
    }

    private func endSession() {
        audioTask?.cancel()
        audioTask = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        translationTask?.cancel()
        translationTask = nil
        backlog.removeAll()
        isRecognizerReady = false
        isTranslatorReady = false
        let recognizer = recognizer
        Task { await recognizer.stop() }
        audio.requestBroadcastStop()
        #if targetEnvironment(simulator)
            audio.endSimulatedBroadcast()
        #endif
        window.show(audioLevel: nil)
        audioStatus = audio.status
    }

    /// Reads the shared ring ten times a second, shows the level, and passes the
    /// samples on to speech recognition.
    private func startAudio() {
        audioTask?.cancel()
        audio.skipToNow()
        audioTask = Task { [weak self] in
            let interval = 0.1
            var elapsed = 0.0
            while !Task.isCancelled {
                guard let self else { return }
                #if targetEnvironment(simulator)
                    self.audio.writeSimulatedAudio(elapsed: elapsed, duration: interval)
                #endif
                let samples = self.audio.readNewSamples()
                let status = self.audio.status
                if status != self.audioStatus {
                    self.audioStatus = status
                    self.refreshWindow()
                }
                let hasAudio = status == .receiving || status == .stalled
                self.window.show(audioLevel: hasAudio ? AudioLevel.meter(for: samples) : nil)
                if self.isRecognizerReady {
                    self.recognizer.append(samples)
                }
                elapsed += interval
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    private func startRecognition() {
        recognitionTask?.cancel()
        isRecognizerReady = false
        let language = language
        recognitionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let updates = try await self.recognizer.start(language: language)
                guard !Task.isCancelled else { return }
                self.isRecognizerReady = true
                self.refreshWindow()
                for try await update in updates {
                    if let settled = self.transcript.apply(update) {
                        self.translate(settled)
                    }
                    self.refreshWindow()
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.isRecognizerReady = false
                self.notice = "语音识别出错：\(error.localizedDescription)"
                self.refreshWindow()
            }
        }
    }

    /// Checks that translation can run. If it cannot, the session carries on with
    /// original-language captions and tells the user why.
    private func prepareTranslation() {
        isTranslatorReady = false
        let language = language
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.translator.prepare(from: language)
                guard self.session.state == .running else { return }
                self.isTranslatorReady = true
            } catch {
                guard self.session.state == .running else { return }
                self.notice = error.localizedDescription
            }
        }
    }

    /// Queues settled speech for translation. One sentence is translated at a time,
    /// in order; if they pile up, the oldest are skipped.
    private func translate(_ entry: Transcript.Entry) {
        guard isTranslatorReady else { return }
        backlog.add(entry)
        guard translationTask == nil else { return }
        translationTask = Task { [weak self] in
            while let self, !Task.isCancelled, let next = self.backlog.next() {
                do {
                    let translation = try await self.translator.translate(next.original)
                    guard !Task.isCancelled else { return }
                    self.transcript.setTranslation(translation, for: next.id)
                    self.refreshWindow()
                } catch {
                    guard !Task.isCancelled else { return }
                    self.notice = "翻译出错：\(error.localizedDescription)"
                }
            }
            self?.translationTask = nil
        }
    }

    /// Shows the current captions, or one line saying what the session is waiting
    /// for when there are none yet.
    private func refreshWindow() {
        let lines = transcript.currentLines
        if lines.rows.isEmpty {
            window.show(CaptionLines(original: waitingText, translation: ""))
        } else {
            window.show(lines)
        }
    }

    private var waitingText: String {
        if notice != nil { return "语音识别没有启动" }
        if !isRecognizerReady { return "正在准备语音识别…" }
        switch audioStatus {
        case .unavailable: return "收不到声音"
        case .notBroadcasting: return "等待录屏开始"
        case .stalled: return "暂时没有声音"
        case .receiving: return "正在听…"
        }
    }
}

import Foundation
import JimakuCore
import Observation
import os

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

    /// What translates the captions. Can be changed while a session runs.
    var engine: TranslationEngine {
        didSet {
            UserDefaults.standard.set(engine.rawValue, forKey: Self.engineKey)
            guard engine != oldValue, session.isActive else { return }
            prepareTranslation()
        }
    }

    /// How captions look. Changes show in the window at once.
    var style: CaptionStyle {
        didSet {
            UserDefaults.standard.set(style.textSize.rawValue, forKey: Self.textSizeKey)
            UserDefaults.standard.set(style.mode.rawValue, forKey: Self.modeKey)
            window.show(style: style)
            refreshWindow()
        }
    }

    let window = CaptionWindow()

    private static let languageKey = "sourceLanguage"
    private static let engineKey = "translationEngine"
    private static let textSizeKey = "captionTextSize"
    private static let modeKey = "captionMode"

    private let audio = AudioMonitor()
    private let recognizer: any SpeechRecognizing
    private let languagePackTranslator: any Translating
    private let appleIntelligenceTranslator: any Translating = AppleIntelligenceTranslator()
    private var isRecognizerReady = false
    private var isTranslatorReady = false
    private var backlog = TranslationBacklog()
    private var audioTask: Task<Void, Never>?
    private var recognitionTask: Task<Void, Never>?
    private var translationTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?
    private let log = Logger(subsystem: "Jimaku", category: "session")

    /// How long the caption window may take to appear or to close before the session
    /// stops waiting for it.
    private static let windowPatience: Duration = .seconds(5)

    init() {
        language =
            UserDefaults.standard.string(forKey: Self.languageKey).flatMap(SourceLanguage.init(rawValue:))
            ?? .english
        let defaults = UserDefaults.standard
        engine = defaults.string(forKey: Self.engineKey).flatMap(TranslationEngine.init(rawValue:)) ?? .languagePack
        style = CaptionStyle(
            textSize: defaults.string(forKey: Self.textSizeKey).flatMap(CaptionStyle.TextSize.init(rawValue:))
                ?? .medium,
            mode: defaults.string(forKey: Self.modeKey).flatMap(CaptionStyle.Mode.init(rawValue:))
                ?? .originalAndTranslation
        )
        #if targetEnvironment(simulator)
            recognizer = ScriptedSpeechRecognizer()
            languagePackTranslator = ScriptedTranslator()
        #else
            recognizer = SystemSpeechRecognizer()
            languagePackTranslator = LanguagePackTranslator()
        #endif
    }

    func prepare() {
        window.onStarted = { [weak self] in self?.windowDidStart() }
        window.onFailedToStart = { [weak self] error in self?.windowFailedToStart(error) }
        window.onClosed = { [weak self] in self?.windowDidClose() }
        window.prepare()
        window.show(style: style)
        // Before a session, the window previews what captions look like.
        window.show(DemoCaptions.lines(at: 0))
        audioStatus = audio.status
    }

    func performPrimaryAction() {
        if session.primaryAction == .start, session.canPerformPrimaryAction, !window.isSupported {
            notice = "这台设备不支持画中画，悬浮窗开不了。"
            return
        }
        let action = session.performPrimaryAction()
        trace("primary action: \(String(describing: action)), now \(String(describing: self.session.state))")
        switch action {
        case .start: begin()
        case .stop: finish()
        case nil: break
        }
    }

    private func begin() {
        notice = nil
        transcript.reset()
        refreshWindow()
        startAudio()
        startRecognition()
        prepareTranslation()
        window.float()
        // If the window has not appeared after a while, give up instead of leaving
        // the button on Stop with nothing on screen.
        watch { controller in
            guard controller.session.state == .starting else { return }
            controller.session.windowFailedToStart()
            controller.endSession()
            controller.window.close()
            controller.notice = "悬浮窗没能打开。请留在 Jimaku 里再点一次开始。"
        }
    }

    private func finish() {
        endSession()
        window.close()
        // If the system never reports the window closed, stop waiting for it.
        watch { controller in
            guard controller.session.state == .stopping else { return }
            controller.session.windowDidClose()
        }
    }

    private func windowDidStart() {
        session.windowDidStart()
        trace("window started, now \(String(describing: self.session.state))")
    }

    private func windowFailedToStart(_ error: Error) {
        let wasActive = session.isActive
        trace("window failed to start: \(error.localizedDescription)")
        session.windowFailedToStart()
        guard wasActive else { return }
        endSession()
        notice = "悬浮窗没能打开：\(error.localizedDescription)"
    }

    private func windowDidClose() {
        let previous = session.state
        trace("window closed while \(String(describing: previous))")
        session.windowDidClose()
        switch previous {
        case .starting:
            // The window went away before it ever appeared, which happens when a
            // start follows a stop too closely. Say so instead of ending silently.
            endSession()
            notice = "悬浮窗没能打开，请再点一次开始。"
        case .running:
            // The user or the system closed the window while the session was running.
            endSession()
        case .idle, .stopping:
            break
        }
    }

    /// Records a lifecycle event in the system log, to diagnose a session on a device.
    private func trace(_ message: String) {
        log.info("\(message, privacy: .public)")
    }

    /// Runs `check` once after `windowPatience`, replacing any earlier pending check.
    private func watch(_ check: @escaping @MainActor (SessionController) -> Void) {
        watchdogTask?.cancel()
        watchdogTask = Task { [weak self] in
            try? await Task.sleep(for: Self.windowPatience)
            guard !Task.isCancelled, let self else { return }
            check(self)
        }
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
        translationTask?.cancel()
        translationTask = nil
        backlog.removeAll()
        notice = nil
        let language = language
        let engine = engine
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.translator.prepare(from: language)
                guard self.session.isActive, self.engine == engine else { return }
                self.isTranslatorReady = true
            } catch {
                guard self.session.isActive, self.engine == engine else { return }
                self.notice = error.localizedDescription
            }
        }
    }

    private var translator: any Translating {
        switch engine {
        case .languagePack: languagePackTranslator
        case .appleIntelligence: appleIntelligenceTranslator
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
        // Outside a session the window keeps its preview caption.
        guard session.isActive else { return }
        let lines = transcript.currentLines
        if lines.rows(in: style.mode).isEmpty {
            // The waiting line goes in the translation slot so it shows in both display modes.
            window.show(CaptionLines(original: "", translation: waitingText))
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

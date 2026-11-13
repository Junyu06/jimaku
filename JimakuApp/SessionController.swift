import Foundation
import JimakuCore
import Observation
import os

/// Runs a caption session: floats the window, reads the audio the broadcast
/// extension captured, sends it to speech recognition, translates what was said,
/// and shows both.
///
/// The rules live in JimakuCore: `CaptionSession` for the lifecycle, `Generation` for
/// telling stale asynchronous results from current ones, `Transcript` for what was
/// said, `TranslationPipeline` for what gets translated when, `CaptionBoard` for
/// how captions are laid out, and `CaptionPlaceholder` for what to say while there
/// is no caption. This class connects them to the system.
@MainActor
@Observable
final class SessionController {
    private(set) var session = CaptionSession()

    /// What is known about the incoming audio while a session runs.
    private(set) var audioStatus: AudioAvailability = .notBroadcasting

    /// What has been said in this session.
    private(set) var transcript = Transcript()

    /// A message for the user when something went wrong. Nil when all is well.
    var notice: String? { windowNotice ?? recognitionNotice ?? translationNotice }

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
            UserDefaults.standard.set(style.lines, forKey: Self.linesKey)
            guard style != oldValue else { return }
            refreshWindow()
        }
    }

    let window = CaptionWindow()

    /// The pixel size of the caption picture the window is showing. The preview
    /// takes its shape from it.
    var frameSize: CGSize { CaptionFrameRenderer.frameSize(height: frameHeight) }

    /// The height of the frame last given to the window. It is set only where
    /// the window is shown something, so the preview never has another shape
    /// than the picture in it.
    private var frameHeight = CaptionFrame.minimumHeight

    private static let languageKey = "sourceLanguage"
    private static let engineKey = "translationEngine"
    private static let textSizeKey = "captionTextSize"
    private static let modeKey = "captionMode"
    private static let linesKey = "captionLines"

    /// How long the caption window may take to appear or to close before the session
    /// stops waiting for it.
    private static let windowPatience: Duration = .seconds(5)

    private let audio = AudioMonitor()
    private let recognizer: any SpeechRecognizing
    private let languagePackSource: any TranslatorSource
    private let appleIntelligenceSource: any TranslatorSource = AppleIntelligenceSource()

    private var windowNotice: String?
    private var recognitionNotice: String?
    private var translationNotice: String?

    private var recognition: CaptionPlaceholder.Readiness = .preparing
    private var pipeline = TranslationPipeline()
    private var board = CaptionBoard(layout: CaptionLayout(style: CaptionStyle()))
    /// Listens for the speaker stopping, so the recognizer can be told at once.
    private var pauses = PauseDetector(sampleRate: AudioRing.sampleRate)
    /// When to show the rest of a translation that is longer than its row, as a
    /// time since the device started. Nil when nothing is waiting.
    private var pageDue: Double?
    /// The board's page that `pageDue` was set for.
    private var pageSeen = 0
    /// How long the first lines of a long translation stay before the rest is
    /// shown, in seconds: about the time it takes to read two lines.
    private static let pageTime = 2.5

    /// Character widths already measured, by row role and column count.
    private var measuredWidths: [String: GlyphWidths] = [:]
    private var translator: (any PreparedTranslator)?

    /// Current for the running session; stale once it ends.
    private var sessionGeneration = Generation()
    /// Current for the translator being prepared or in use; stale once the engine
    /// changes or the session ends.
    private var translatorGeneration = Generation()
    private var translatorToken: Generation.Token?

    private var audioTask: Task<Void, Never>?
    private var recognitionTask: Task<Void, Never>?
    private var recognizerStopTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?
    private let log = Logger(subsystem: "Jimaku", category: "session")

    init() {
        let defaults = UserDefaults.standard
        language = defaults.string(forKey: Self.languageKey).flatMap(SourceLanguage.init(rawValue:)) ?? .english
        engine = defaults.string(forKey: Self.engineKey).flatMap(TranslationEngine.init(rawValue:)) ?? .languagePack
        style = CaptionStyle(
            textSize: defaults.string(forKey: Self.textSizeKey).flatMap(CaptionStyle.TextSize.init(rawValue:))
                ?? .medium,
            mode: defaults.string(forKey: Self.modeKey).flatMap(CaptionStyle.Mode.init(rawValue:))
                ?? .originalAndTranslation,
            lines: defaults.object(forKey: Self.linesKey) as? Int ?? CaptionStyle().lines
        )
        #if targetEnvironment(simulator)
            recognizer = ScriptedSpeechRecognizer()
            languagePackSource = ScriptedSource()
        #else
            recognizer = SystemSpeechRecognizer()
            languagePackSource = LanguagePackSource()
        #endif
    }

    func prepare() {
        window.onStarted = { [weak self] in self?.windowDidStart() }
        window.onFailedToStart = { [weak self] error in self?.windowFailedToStart(error) }
        window.onClosed = { [weak self] in self?.windowDidClose() }
        window.prepare()
        refreshWindow()
        audioStatus = audio.status
    }

    // MARK: Starting and stopping

    func performPrimaryAction() {
        if session.primaryAction == .start, session.canPerformPrimaryAction, !window.isSupported {
            windowNotice = "这台设备不支持画中画，悬浮窗开不了。"
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
        windowNotice = nil
        recognitionNotice = nil
        translationNotice = nil
        transcript = Transcript(rules: language.chunkRules)
        pipeline.reset()
        board = CaptionBoard(layout: layout)
        pauses = PauseDetector(sampleRate: AudioRing.sampleRate)
        pageDue = nil
        pageSeen = board.page
        recognition = .preparing
        let token = sessionGeneration.advance()
        audio.beginCapture()
        refreshWindow()
        startAudio(for: token)
        startRecognition(for: token)
        prepareTranslation()
        window.float()
        // If the window has not appeared after a while, give up instead of leaving
        // the button on Stop with nothing on screen.
        watch { controller in
            guard controller.session.state == .starting else { return }
            controller.session.windowFailedToStart()
            controller.endSession()
            // Cut the old window off, so nothing it reports later reaches a new session.
            controller.window.abandon()
            controller.windowNotice = "悬浮窗没能打开。请留在 Jimaku 里再点一次开始。"
        }
    }

    private func finish() {
        endSession()
        window.close()
        // If the system never reports the window closed, stop waiting for it.
        watch { controller in
            guard controller.session.state == .stopping else { return }
            // Cut the old window off before a new session may start, so a close it
            // reports late cannot end that session.
            controller.window.abandon()
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
        windowNotice = "悬浮窗没能打开：\(error.localizedDescription)"
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
            windowNotice = "悬浮窗没能打开，请再点一次开始。"
        case .running:
            // The user or the system closed the window while the session was running.
            endSession()
        case .idle, .stopping:
            break
        }
    }

    /// Stops everything a session started. Results that arrive afterwards belong to
    /// stale generations and are ignored.
    private func endSession() {
        sessionGeneration.invalidate()
        translatorGeneration.invalidate()
        translatorToken = nil
        translator = nil
        pipeline.reset()
        recognition = .preparing

        audioTask?.cancel()
        audioTask = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        // Stops run one after another, and the next start waits for the last one.
        let recognizer = recognizer
        let previousStop = recognizerStopTask
        recognizerStopTask = Task {
            await previousStop?.value
            await recognizer.stop()
        }

        audio.endCapture()
        #if targetEnvironment(simulator)
            audio.endSimulatedBroadcast()
        #endif
        window.show(audioLevel: nil)
        audioStatus = audio.status
    }

    // MARK: Audio

    /// Reads the shared ring ten times a second, shows the level, and passes the
    /// samples on to speech recognition.
    private func startAudio(for token: Generation.Token) {
        audioTask?.cancel()
        audioTask = Task { [weak self] in
            let interval = 0.1
            var elapsed = 0.0
            while !Task.isCancelled {
                guard let self, self.sessionGeneration.isCurrent(token) else { return }
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
                if self.recognition == .ready {
                    // When the speaker stops, the recognizer is asked to settle
                    // on the sentence now. That is what ends most captions. It
                    // is told between the samples before the pause and those
                    // after it.
                    var handed = 0
                    for place in self.pauses.take(samples) {
                        self.recognizer.append(Array(samples[handed..<place]))
                        self.recognizer.speakerPaused()
                        handed = place
                    }
                    self.recognizer.append(Array(samples[handed...]))
                    // Audio that never goes quiet gives no such pause, so a guess
                    // that stops changing ends a caption as well.
                    let kept = self.transcript.elapse(to: ProcessInfo.processInfo.systemUptime)
                    if !kept.isEmpty {
                        kept.forEach { self.pipeline.settle($0) }
                        self.pump()
                        self.refreshWindow()
                    }
                }
                self.turnPageIfDue()
                elapsed += interval
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    // MARK: Recognition

    private func startRecognition(for token: Generation.Token) {
        recognitionTask?.cancel()
        let language = language
        let previousStop = recognizerStopTask
        recognitionTask = Task { [weak self] in
            // Let the previous session's recognizer finish shutting down first.
            await previousStop?.value
            guard let self, self.sessionGeneration.isCurrent(token) else { return }
            do {
                let updates = try await self.recognizer.start(language: language)
                guard self.sessionGeneration.isCurrent(token) else { return }
                self.recognition = .ready
                self.refreshWindow()
                for try await update in updates {
                    guard self.sessionGeneration.isCurrent(token) else { return }
                    for kept in self.transcript.apply(update, at: ProcessInfo.processInfo.systemUptime) {
                        self.pipeline.settle(kept)
                    }
                    self.pump()
                    self.refreshWindow()
                }
                // The recognizer stopped on its own while the session is still running.
                guard self.sessionGeneration.isCurrent(token) else { return }
                self.recognition = .failed
                self.recognitionNotice = "语音识别停了。请点停止，再重新开始。"
                self.refreshWindow()
            } catch {
                guard self.sessionGeneration.isCurrent(token), !(error is CancellationError) else { return }
                self.recognition = .failed
                self.recognitionNotice = "语音识别出错：\(error.localizedDescription)"
                self.refreshWindow()
            }
        }
    }

    // MARK: Translation

    /// Gets a translator for the current engine and language. If that fails, the
    /// session carries on with original-language captions and tells the user why.
    private func prepareTranslation() {
        let token = translatorGeneration.advance()
        translatorToken = token
        translator = nil
        translationNotice = nil
        pipeline.setReadiness(.preparing)
        refreshWindow()

        let source = source(for: engine)
        let language = language
        Task { [weak self] in
            do {
                let prepared = try await source.prepare(from: language)
                guard let self, self.translatorGeneration.isCurrent(token) else { return }
                self.translator = prepared
                self.pipeline.setReadiness(.ready)
                self.refreshWindow()
                self.pump()
            } catch {
                guard let self, self.translatorGeneration.isCurrent(token) else { return }
                self.pipeline.setReadiness(.failed)
                self.translationNotice = error.localizedDescription
                self.refreshWindow()
            }
        }
    }

    private func source(for engine: TranslationEngine) -> any TranslatorSource {
        switch engine {
        case .languagePack: languagePackSource
        case .appleIntelligence: appleIntelligenceSource
        }
    }

    /// Sends the next kept piece of speech to the translator, if one is waiting.
    private func pump() {
        guard let translator, let token = translatorToken, let entry = pipeline.takeNext() else { return }
        Task { [weak self] in
            let result: Result<String, Error>
            do {
                result = .success(try await translator.translate(entry.original))
            } catch {
                result = .failure(error)
            }
            // The engine changed or the session ended while this was being translated.
            guard let self, self.translatorGeneration.isCurrent(token) else { return }
            switch result {
            case .success(let translation):
                self.transcript.setTranslation(translation, for: entry.id)
                self.pipeline.finishCurrent(succeeded: true)
                self.translationNotice = nil
                self.refreshWindow()
                self.pump()
            case .failure(let error):
                // Translation counts as unavailable until one succeeds, so the
                // window falls back to the original. This piece is handed out
                // again by a later recognizer update; retrying it at once would
                // spin. Whatever else is waiting goes on now.
                self.transcript.translationFailed(for: entry.id)
                self.pipeline.finishCurrent(succeeded: false)
                self.translationNotice = "翻译出错：\(error.localizedDescription)"
                self.refreshWindow()
                self.pump()
            }
        }
    }

    // MARK: The window's content

    /// The layout for the current style. When translation cannot run, the original
    /// takes the main row.
    private var layout: CaptionLayout {
        var layout = CaptionLayout(
            style: style,
            translationAvailable: !session.isActive || pipeline.isTranslationAvailable
        )
        let original = widths(for: layout.original)
        let translation = widths(for: layout.translation)
        layout.original?.widths = original
        layout.translation?.widths = translation
        return layout
    }

    /// The measured character widths for a row, measured once per kind of row.
    private func widths(for row: CaptionLayout.Row?) -> GlyphWidths {
        guard let row else { return .estimated }
        let key = "\(row.role)-\(row.columns)"
        if let known = measuredWidths[key] { return known }
        let measured = CaptionFrameRenderer.glyphWidths(role: row.role, columns: row.columns)
        measuredWidths[key] = measured
        return measured
    }

    /// Shows the current captions, or one line saying what the session is waiting
    /// for when there are none yet. Outside a session, shows a sample caption.
    private func refreshWindow() {
        let layout = layout
        let frameHeight = CaptionFrame.height(for: layout)
        if frameHeight != self.frameHeight { self.frameHeight = frameHeight }
        guard session.isActive else {
            window.show(.rows(CaptionBoard.rows(for: DemoCaptions.lines(at: 0), layout: layout)), frameHeight: frameHeight)
            return
        }
        if layout == board.layout {
            board.show(transcript, translating: pipeline.hasWork)
        } else {
            board.relay(layout, showing: transcript, translating: pipeline.hasWork)
        }
        if board.page != pageSeen {
            // The translation row shows something new: if there is more of it
            // than fits, its reading time starts now.
            pageSeen = board.page
            pageDue = board.hasMore ? ProcessInfo.processInfo.systemUptime + Self.pageTime : nil
        }
        if board.isEmpty {
            let available = pipeline.isTranslationAvailable
            let placeholder = CaptionPlaceholder.choose(
                recognition: recognition,
                audio: audioStatus,
                translation: available ? pipeline.readiness : .failed,
                mode: style.mode.effective(translationAvailable: available),
                hasSpeech: !transcript.entries.isEmpty || !transcript.pending.isEmpty
            )
            window.show(.notice(text(for: placeholder)), frameHeight: frameHeight)
        } else {
            window.show(.rows(board.rows), frameHeight: frameHeight)
        }
    }

    /// Moves on to the rest of a translation longer than its row, once its first
    /// lines have been up for `pageTime`.
    private func turnPageIfDue() {
        guard session.isActive, let due = pageDue, ProcessInfo.processInfo.systemUptime >= due else { return }
        pageDue = nil
        board.showMore()
        refreshWindow()
    }

    private func text(for placeholder: CaptionPlaceholder) -> String {
        switch placeholder {
        case .recognitionFailed: "语音识别没有启动"
        case .preparingRecognition: "正在准备语音识别…"
        case .audioUnavailable: "收不到声音"
        case .waitingForBroadcast: "等待录屏开始"
        case .noSound: "暂时没有声音"
        case .listening: "正在听…"
        case .preparingTranslation: "正在准备翻译…"
        case .translating: "正在翻译…"
        case .translationUnavailable: "翻译用不了"
        }
    }

    // MARK: Helpers

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
}

import Foundation
import JimakuCore
import Observation
import UIKit
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

    /// Whether the app owes the user the system's broadcast sheet without a
    /// tap. The start page hands this to the system's control, which takes
    /// the request when it is on the page to be pressed.
    var broadcastSheetIsOwed: Bool { sheetRequest.isOwed }

    /// What has been said in this session.
    private(set) var transcript = Transcript()

    /// A message for the user when something went wrong. Nil when all is well.
    var notice: String? {
        windowNotice ?? cannotStartNotice ?? recognitionNotice ?? packFailure
            ?? translationNotice.map { $0 + engineHint }
    }

    /// Why the language pack of the pair in use did not arrive. It matters only
    /// while the language-pack engine is the one in use; with the other engine
    /// it would hide what that engine has to say.
    private var packFailure: String? {
        settings.engine == .languagePack ? packFailures[languages] : nil
    }

    /// Shown after a start was refused, for as long as the device still can do
    /// no pair.
    private var cannotStartNotice: String? {
        guard refusedStart, !settings.canStart else { return nil }
        return "这台设备现在识别不了\(languages.spoken.spokenName)，或者没法把它翻译成\(languages.target.writtenName)，开始不了。"
    }

    /// Added to a message about the language model failing, while changing the
    /// engine would help: the language packs can translate these languages.
    private var engineHint: String {
        modelFailed && settings.engineChoices.contains(.languagePack) ? "可以把「翻译引擎」换成语言包。" : ""
    }

    /// The languages and the engine: what the user chose, what the device can
    /// do, and what a session uses. The rules are in `LanguageSettings`.
    private(set) var settings: LanguageSettings {
        didSet {
            guard settings.chosen != oldValue.chosen || settings.chosenEngine != oldValue.chosenEngine
                || settings.kept != oldValue.kept || settings.shownBefore != oldValue.shownBefore
            else { return }
            UserDefaults.standard.set(settings.chosen.spoken.identifier, forKey: Self.spokenKey)
            UserDefaults.standard.set(settings.chosen.target.identifier, forKey: Self.targetKey)
            UserDefaults.standard.set(settings.chosenEngine.rawValue, forKey: Self.engineKey)
            UserDefaults.standard.set(settings.kept == .target ? "target" : "spoken", forKey: Self.keptKey)
            UserDefaults.standard.set(settings.shownBefore?.identifier, forKey: Self.shownBeforeKey)
        }
    }

    /// The language spoken in what the user is watching, and the one captions
    /// are translated into.
    var languages: LanguagePair { settings.pair }

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

    private static let spokenKey = "spokenLanguage"
    private static let targetKey = "targetLanguage"
    /// Which of the two the user chose last: "spoken" or "target".
    private static let keptKey = "languageChosenLast"
    /// The language that was on the other side when the user last chose.
    private static let shownBeforeKey = "languageShownBefore"
    /// Where a version that knew only English and Japanese kept the spoken one.
    private static let legacySpokenKey = "sourceLanguage"
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
    private let supportSource: any LanguageSupportSource
    private let appleIntelligenceSource: any TranslatorSource = AppleIntelligenceSource()

    private var sheetRequest = BroadcastSheetRequest()

    private var windowNotice: String?
    private var recognitionNotice: String?
    private var translationNotice: String?
    /// Why a language pack the user asked for did not arrive, by the pair it
    /// was for. Only the one for the pair in use is shown.
    private var packFailures: [LanguagePair: String] = [:]
    /// A start was refused because the device could do no pair.
    private var refusedStart = false

    private var recognition: CaptionPlaceholder.Readiness = .preparing
    private var pipeline = TranslationPipeline()
    private var board = CaptionBoard(layout: CaptionLayout(style: CaptionStyle()))
    /// Listens for the speaker stopping, so the recognizer can be told at once.
    private var pauses = PauseDetector(sampleRate: AudioRing.sampleRate)
    /// Speech the recognizer finalized on a short quiet, until the quiet has
    /// lasted long enough to be sure the speaker stopped.
    private var held = HeldSpeech()
    /// Translations by the text they translate, so that one started ahead of
    /// time for speech that is being held is there when its caption is kept.
    private let translations = TranslationsAhead()
    /// When to show the rest of a translation that is longer than its row, as a
    /// time since the device started. Nil when nothing is waiting.
    private var pageDue: Double?
    /// The board's page that `pageDue` was set for.
    private var pageSeen = 0
    /// Character widths already measured, by row role and column count.
    private var measuredWidths: [String: GlyphWidths] = [:]
    private var translator: (any PreparedTranslator)?
    /// The engine and language pack the session's translator was last prepared
    /// with. Nil outside a session.
    private var prepared: LanguageSettings.Preparation?
    /// Whether preparing the translator failed because its language pack was
    /// missing, and whether it failed with the language model as the engine.
    private var missedPack = false
    private var modelFailed = false
    /// The last question put to the system about the languages. Questions are
    /// asked one after another, so their answers arrive in order.
    private var asking: Task<Void, Never>?
    /// Looks again for each language pack that is being downloaded, by pair.
    private var packWatches: [LanguagePair: Task<Void, Never>] = [:]

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
        settings = LanguageSettings(
            chosen: LanguagePair.restored(
                spoken: defaults.string(forKey: Self.spokenKey),
                target: defaults.string(forKey: Self.targetKey),
                legacySpoken: defaults.string(forKey: Self.legacySpokenKey),
                preferred: Locale.preferredLanguages
            ),
            engine: defaults.string(forKey: Self.engineKey).flatMap(TranslationEngine.init(rawValue:)) ?? .languagePack,
            kept: defaults.string(forKey: Self.keptKey) == "target" ? .target : .spoken,
            shownBefore: defaults.string(forKey: Self.shownBeforeKey).flatMap(CaptionLanguage.init(identifier:))
        )
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
            supportSource = ScriptedLanguageSupport()
        #else
            recognizer = SystemSpeechRecognizer()
            languagePackSource = LanguagePackSource()
            supportSource = SystemLanguageSupport()
        #endif
    }

    func prepare() {
        window.onStarted = { [weak self] in self?.windowDidStart() }
        window.onFailedToStart = { [weak self] error in self?.windowFailedToStart(error) }
        window.onClosed = { [weak self] in self?.windowDidClose() }
        window.prepare()
        refreshWindow()
        audioStatus = audio.status
        refreshLanguageSupport()
    }

    // MARK: Languages

    /// Asks the system again what it can do with the languages: when the app
    /// opens, when it comes back to the front, and around the download of a
    /// language pack.
    func refreshLanguageSupport() {
        ask()
    }

    /// Asks the system and takes its answer. A question waits for the one
    /// before it: the system is asked about each pair in turn, and two rounds
    /// running at once could each see some pairs before and some after a
    /// change.
    @discardableResult
    private func ask() -> Task<Void, Never> {
        let previous = asking
        let task = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            let question = self.settings.beginAsking()
            let support = await self.supportSource.support()
            guard self.settings.take(support, asked: question) else { return }
            // A pack that has arrived has no failure to report any more.
            self.packFailures = self.packFailures.filter { support.packStatus(for: $0.key) == .downloadable }
            self.reconcileTranslation()
        }
        asking = task
        return task
    }

    func choose(spoken: CaptionLanguage) {
        settings.choose(spoken: spoken)
    }

    func choose(target: CaptionLanguage) {
        settings.choose(target: target)
    }

    /// Can be changed while a session runs.
    func choose(engine: TranslationEngine) {
        settings.chosenEngine = engine
        reconcileTranslation()
    }

    /// The system's download sheet for the language pack of `pair` was closed,
    /// with the error it gave if any. The download may still be going on, so
    /// the system is asked about that pack again: at once, then after each of
    /// twenty waits of three seconds and forty of fifteen, until the pack is no
    /// longer waiting to be downloaded. Each look also waits for the system's
    /// answer, so this lasts eleven minutes or somewhat more. After that the
    /// next look is when the app comes back to the front. Each pair asked for
    /// has a watch of its own.
    func languagePackRequestEnded(for pair: LanguagePair, error: (any Error)?) {
        packFailures[pair] = error.map {
            "\(pair.spoken.spokenName)翻译成\(pair.target.writtenName)的语言包没下载成：\($0.localizedDescription)"
        }
        packWatches[pair]?.cancel()
        packWatches[pair] = Task { [weak self] in
            for look in 0...60 {
                if look > 0 { try? await Task.sleep(for: .seconds(look <= 20 ? 3 : 15)) }
                guard let self, !Task.isCancelled else { return }
                await self.ask().value
                guard self.settings.support?.packStatus(for: pair) == .downloadable else { break }
            }
            // A watch that was replaced by a newer one for the same pair
            // leaves the newer one in place.
            if !Task.isCancelled { self?.packWatches[pair] = nil }
        }
    }

    /// Prepares the running session's translator again when what it was
    /// prepared with no longer holds: another engine is in use, or its language
    /// pack has arrived.
    private func reconcileTranslation() {
        guard session.isActive, let prepared,
            settings.needsPreparingAgain(after: prepared, isReady: translator != nil, missedPack: missedPack)
        else { return }
        prepareTranslation()
    }

    // MARK: Starting and stopping

    func performPrimaryAction() {
        if session.primaryAction == .start, session.canPerformPrimaryAction, !window.isSupported {
            windowNotice = "这台设备不支持画中画，悬浮窗开不了。"
            return
        }
        if session.primaryAction == .start, session.canPerformPrimaryAction, !settings.canStart {
            // The system has answered, and there is no pair this device can do.
            refusedStart = true
            return
        }
        refusedStart = false
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
        // The languages stay as they are until the session ends.
        settings.lock()
        transcript = Transcript(rules: languages.spoken.chunkRules)
        pipeline.reset()
        board = CaptionBoard(layout: layout)
        pauses = PauseDetector(sampleRate: AudioRing.sampleRate)
        held = HeldSpeech()
        translations.reset()
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
        let wasStarting = session.state == .starting
        session.windowDidStart()
        trace("window started, now \(String(describing: self.session.state))")
        // With no broadcast running, the app owes the user the system's sheet
        // from here on, so that Start needs no second tap in the app. The page
        // must show the same thing the request was judged by.
        let status = audio.status
        if status != audioStatus {
            audioStatus = status
            refreshWindow()
        }
        sheetRequest.windowAppeared(sessionWasStarting: wasStarting, audio: status)
    }

    /// The system's control is on the page and can be pressed. Returns whether
    /// to press it for the user, and uses up what was owed.
    func takeBroadcastSheetRequest() -> Bool {
        sheetRequest.take(
            sessionRunning: session.state == .running,
            audio: audio.status,
            appIsActive: UIApplication.shared.applicationState == .active
        )
    }

    /// The user pressed the system's control or left the app: what was owed
    /// is not kept.
    func dropBroadcastSheetRequest() {
        guard sheetRequest.isOwed else { return }
        sheetRequest.drop()
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
        sheetRequest.drop()
        translatorGeneration.invalidate()
        translatorToken = nil
        translator = nil
        prepared = nil
        settings.unlock()
        translations.reset()
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
        audioStatus = audio.status
    }

    // MARK: Audio

    /// Reads the shared ring some thirty times a second and passes the samples on
    /// to speech recognition. How often it looks is part of how soon a pause is
    /// noticed.
    private func startAudio(for token: Generation.Token) {
        audioTask?.cancel()
        audioTask = Task { [weak self] in
            let interval = 0.03
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
                if self.recognition == .ready {
                    // On a short quiet the recognizer is asked to settle on what
                    // was said, between the samples before the quiet and those
                    // after it, so the words and their translation are ready
                    // early. They become a caption when the quiet has lasted
                    // long enough to be sure the speaker stopped. That is what
                    // ends most captions.
                    var handed = 0
                    for pause in self.pauses.events(in: samples) {
                        self.recognizer.append(Array(samples[handed..<pause.place]))
                        handed = pause.place
                        // The recognizer's own clock, which the ends of its
                        // results are on.
                        let time = self.recognizer.audioTime
                        if pause.isCertain {
                            if let update = self.held.confirm(at: time) { self.take(update) }
                        } else {
                            self.recognizer.speakerPaused()
                            self.held.asked(at: time)
                        }
                    }
                    self.recognizer.append(Array(samples[handed...]))
                    // An answer the recognizer owed has not come: what was
                    // held ends without it.
                    if let update = self.held.overdue(at: self.recognizer.audioTime) { self.take(update) }
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
        let language = languages.spoken
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
                for try await heard in updates {
                    guard self.sessionGeneration.isCurrent(token) else { return }
                    let update = self.held.take(heard.update, endingAt: heard.end)
                    if case .final = heard.update, case .partial = update { self.translateAhead() }
                    self.take(update)
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

    /// Gives the transcript an update and passes on what it keeps.
    private func take(_ update: RecognitionUpdate) {
        for kept in transcript.apply(update, at: ProcessInfo.processInfo.systemUptime) {
            pipeline.settle(kept)
        }
        pump()
        refreshWindow()
    }

    /// Starts translating what is being held, as the pieces it will be kept in
    /// if the speaker has stopped. If they go on instead, these translations
    /// are not used.
    private func translateAhead() {
        guard let translator, !held.text.isEmpty else { return }
        var ahead = transcript
        for piece in ahead.apply(.final(held.text), at: ProcessInfo.processInfo.systemUptime) {
            _ = translations.translation(of: piece.original) { try await translator.translate($0) }
        }
    }

    // MARK: Translation

    /// Gets a translator for the current engine and languages. If that fails, the
    /// session carries on with original-language captions and tells the user why.
    private func prepareTranslation() {
        let token = translatorGeneration.advance()
        translatorToken = token
        translator = nil
        translations.reset()
        translationNotice = nil
        pipeline.setReadiness(.preparing)
        refreshWindow()

        prepared = settings.preparation
        missedPack = false
        modelFailed = false
        let engine = settings.engine
        let source = source(for: engine)
        let languages = languages
        Task { [weak self] in
            do {
                let prepared = try await source.prepare(for: languages)
                guard let self, self.translatorGeneration.isCurrent(token) else { return }
                self.translator = prepared
                self.pipeline.setReadiness(.ready)
                self.refreshWindow()
                self.pump()
            } catch {
                guard let self, self.translatorGeneration.isCurrent(token) else { return }
                self.pipeline.setReadiness(.failed)
                if case TranslationSetupError.languagePackMissing = error { self.missedPack = true }
                self.modelFailed = engine == .appleIntelligence
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
        // Asked for here and not inside the task, so that a task which starts
        // after the translator has changed cannot put the old translator's
        // work among the new one's.
        let translation = translations.translation(of: entry.original) { try await translator.translate($0) }
        Task { [weak self] in
            let result = await translation.result
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
            pageDue = board.hasMore ? ProcessInfo.processInfo.systemUptime + board.pageTime : nil
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
        case .waitingForBroadcast: "录屏未打开"
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

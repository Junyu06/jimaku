import AVFoundation
import JimakuCore
import SwiftUI
import Translation

/// The app's one screen: a preview of the caption window, the button that starts or
/// stops a session, the settings, and the captions of the current session.
struct StartView: View {
    @State private var controller = SessionController()
    @Environment(\.scenePhase) private var scenePhase

    /// The page that says why the recording is needed, while it is shown.
    @State private var explanation: ExplanationUse?
    /// Set when that page was closed with its button before a first session.
    @State private var startsAfterExplanation = false

    private var isRunning: Bool { controller.session.isActive }

    var body: some View {
        Form {
            Section {
                CaptionPreview(layer: controller.window.displayLayer)
                    .aspectRatio(controller.frameSize, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    .listRowSeparator(.hidden)

                if guide == .openRecording {
                    // Drawn as a button and not one: the system's control lies
                    // over all of it and takes the tap.
                    Button {} label: {
                        Text("打开录屏")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .overlay {
                        BroadcastPicker(
                            sheetIsOwed: controller.broadcastSheetIsOwed,
                            takeSheetRequest: { controller.takeBroadcastSheetRequest() },
                            pressed: { controller.dropBroadcastSheetRequest() }
                        )
                        .accessibilityIdentifier("broadcastPicker")
                    }
                    .listRowSeparator(.hidden)

                    // The reason in a few words, and the rest behind the
                    // question mark. In a row of its own: in one row with the
                    // wide button, a tap on that button opened this too.
                    Button {
                        explanation = .asked
                    } label: {
                        HStack(spacing: 5) {
                            Text("用来听视频的声音")
                                .foregroundStyle(Color.secondary)
                            Image(systemName: "questionmark.circle")
                        }
                        .font(.footnote)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("为什么要打开录屏")
                    .accessibilityIdentifier("recordingGuide")
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .listRowSeparator(.hidden)
                } else if let guide {
                    Text(text(for: guide))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("recordingGuide")
                        .listRowSeparator(.hidden)
                }

                Button {
                    if controller.startNeedsExplanation {
                        explanation = .beforeStart
                    } else {
                        controller.performPrimaryAction()
                    }
                } label: {
                    Text(primaryActionTitle)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                // While the recording is the thing to open, Stop steps back:
                // from the tap on Start, so it does not change when the wide
                // button arrives.
                .prominent(!(isRunning && controller.audioStatus == .notBroadcasting))
                .disabled(!controller.session.canPerformPrimaryAction)
                .accessibilityIdentifier("primaryAction")
                .listRowSeparator(.hidden)

                if let notice = controller.notice {
                    Text(notice)
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("notice")
                }
            }

            Section("设置") {
                LanguageRows(controller: controller, isRunning: isRunning)

                Picker("显示", selection: $controller.style.mode) {
                    Text("原文和译文").tag(CaptionStyle.Mode.originalAndTranslation)
                    Text("只显示译文").tag(CaptionStyle.Mode.translationOnly)
                }
                .accessibilityIdentifier("mode")

                LabeledContent("字号") {
                    Picker("字号", selection: $controller.style.textSize) {
                        Text("小").tag(CaptionStyle.TextSize.small)
                        Text("中").tag(CaptionStyle.TextSize.medium)
                        Text("大").tag(CaptionStyle.TextSize.large)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 220)
                    .accessibilityIdentifier("textSize")
                }

                LabeledContent("译文行数") {
                    Picker("译文行数", selection: $controller.style.lines) {
                        ForEach(CaptionStyle.lineChoices, id: \.self) { lines in
                            Text("\(lines)").tag(lines)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 220)
                    .accessibilityIdentifier("lines")
                }
            }

            // Always there: the line under the wide button shows only while
            // the recording is off, and the page comes by itself only once.
            Section("帮助") {
                Button("为什么要打开录屏") { explanation = .asked }
                    .accessibilityIdentifier("recordingHelp")
            }

            if !controller.transcript.entries.isEmpty {
                Section("这一次的字幕") {
                    ForEach(controller.transcript.entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.original)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            if let translation = entry.translation {
                                Text(translation)
                            }
                        }
                        .textSelection(.enabled)
                    }
                }
            }
        }
        .onAppear { controller.prepare() }
        .sheet(item: $explanation, onDismiss: startIfExplained) { use in
            RecordingExplanationView(buttonTitle: use == .beforeStart ? "继续" : "确认") {
                controller.explanationWasRead()
                startsAfterExplanation = use == .beforeStart
                explanation = nil
            }
            // As tall as what it says where the system gives a sheet a size
            // of its own; elsewhere the sheet is the system's.
            .presentationSizing(.form.fitted(horizontal: false, vertical: true))
        }
        .onChange(of: scenePhase) { _, phase in
            // A language pack may have been downloaded in the system's settings.
            if phase == .active {
                controller.refreshLanguageSupport()
            } else {
                // A sheet the app owed is not shown to a user who has left.
                controller.dropBroadcastSheetRequest()
                // Nor is a session started for them.
                startsAfterExplanation = false
            }
        }
    }

    /// What the page says about the screen recording. Nil until the caption
    /// window is up and while sound arrives.
    private var guide: RecordingGuide? {
        RecordingGuide.choose(windowIsUp: controller.session.state == .running, audio: controller.audioStatus)
    }

    /// A label, not a sentence: short enough to be read at a glance. Where the
    /// recording is offered the row is a button and has its own words.
    private func text(for guide: RecordingGuide) -> String {
        switch guide {
        case .openRecording: ""
        case .noSound: "录屏已打开，暂无声音"
        case .cannotHear: "收不到其他 App 的声音"
        }
    }

    /// Starts the session the explanation stood before, once the page is gone:
    /// the caption window and the system's sheet come up over the start page.
    /// Not for a user who has left the app while the page was going.
    private func startIfExplained() {
        let closedWithButton = startsAfterExplanation
        startsAfterExplanation = false
        guard
            RecordingExplanation.startsSessionOnceGone(
                closedWithButtonBeforeStart: closedWithButton,
                appIsActive: scenePhase == .active,
                sessionIsIdle: controller.session.state == .idle)
        else { return }
        controller.performPrimaryAction()
    }

    private var primaryActionTitle: String {
        switch controller.session.primaryAction {
        case .start: "开始"
        case .stop: "停止"
        }
    }
}

/// Why the explanation of the recording is on the screen.
private enum ExplanationUse: Identifiable {
    /// Before the first session: closing it with its button starts the session.
    case beforeStart
    /// The user asked for it.
    case asked

    var id: Self { self }
}

extension View {
    /// The filled button style, or the quieter bordered one.
    @ViewBuilder
    fileprivate func prominent(_ isProminent: Bool) -> some View {
        if isProminent {
            buttonStyle(.borderedProminent)
        } else {
            buttonStyle(.bordered)
        }
    }
}

/// Hosts the caption layer in SwiftUI.
private struct CaptionPreview: UIViewRepresentable {
    let layer: AVSampleBufferDisplayLayer

    func makeUIView(context: Context) -> HostView {
        let view = HostView()
        view.hostedLayer = layer
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ view: HostView, context: Context) {}

    final class HostView: UIView {
        var hostedLayer: CALayer?

        override func layoutSubviews() {
            super.layoutSubviews()
            hostedLayer?.frame = bounds
        }
    }
}

/// The rows that choose the languages and the engine.
///
/// A view of its own, reading only the settings: the form around it is drawn
/// again with every caption, and a menu whose rows are made again while it is
/// open does not take a tap.
private struct LanguageRows: View {
    let controller: SessionController
    let isRunning: Bool

    /// The language pack the user asked to download, and the pair it is for.
    /// The system shows its own sheet for it. Both are cleared when the sheet
    /// has closed, so the request cannot run a second time by itself.
    @State private var packRequest: TranslationSession.Configuration?
    @State private var requestedPair: LanguagePair?

    var body: some View {
        Picker("说话的语言", selection: spoken) {
            ForEach(controller.settings.spokenChoices) { language in
                Text(language.spokenName).tag(language)
            }
        }
        .disabled(isRunning)
        .accessibilityIdentifier("language")
        // On one row that is always there. On a group of rows it would run
        // once for each.
        .translationTask(packRequest) { session in
            // Shows the system's sheet, which asks before it downloads. The
            // session is not Sendable and this call leaves the main actor; that
            // is safe because nothing else uses this session.
            nonisolated(unsafe) let unisolated = session
            var failure: (any Error)?
            do {
                try await unisolated.prepareTranslation()
            } catch is CancellationError {
            } catch {
                failure = error
            }
            let pair = requestedPair
            packRequest = nil
            requestedPair = nil
            if let pair { controller.languagePackRequestEnded(for: pair, error: failure) }
        }

        Picker("翻译成", selection: target) {
            ForEach(controller.settings.targetChoices) { language in
                Text(language.writtenName).tag(language)
            }
        }
        .disabled(isRunning)
        .accessibilityIdentifier("target")

        // While the device reports an engine that can translate these
        // languages, or has not answered yet, both engines are listed. One
        // that cannot is greyed out, with the reason after its name. The
        // reason is part of the one line: a menu made by a picker shows no
        // second line.
        if controller.settings.canTranslate {
            Picker("翻译引擎", selection: engine) {
                ForEach(TranslationEngine.allCases, id: \.self) { engine in
                    let obstacle = controller.settings.obstacle(to: engine)
                    Text(obstacle.map { "\(name(of: engine))（\(reason(for: $0))）" } ?? name(of: engine))
                        .tag(engine)
                        .selectionDisabled(obstacle != nil)
                }
            }
            .accessibilityIdentifier("engine")
        } else {
            // The device's answer names no engine that can translate these
            // languages, whether it denied them or said nothing about them,
            // so a picker would have no line to show as chosen. The row says
            // only that. A session that is running goes on with what it has
            // and says what goes wrong.
            LabeledContent("翻译引擎") {
                Text("系统没有报告可用的翻译引擎")
            }
            .accessibilityIdentifier("engine")
        }

        if controller.settings.needsLanguagePack {
            LabeledContent("语言包还没下载") {
                Button("下载") { requestLanguagePack() }
                    .disabled(packRequest != nil)
                    .accessibilityIdentifier("downloadLanguagePack")
            }
        }
    }

    private var spoken: Binding<CaptionLanguage> {
        Binding(get: { controller.languages.spoken }, set: { controller.choose(spoken: $0) })
    }

    private var target: Binding<CaptionLanguage> {
        Binding(get: { controller.languages.target }, set: { controller.choose(target: $0) })
    }

    private var engine: Binding<TranslationEngine> {
        Binding(get: { controller.settings.engine }, set: { controller.choose(engine: $0) })
    }

    private func name(of engine: TranslationEngine) -> String {
        switch engine {
        case .languagePack: "语言包"
        case .appleIntelligence: "Apple Intelligence"
        }
    }

    /// Why an engine cannot be chosen, short enough to sit after its name.
    private func reason(for obstacle: EngineObstacle) -> String {
        switch obstacle {
        case .deviceCannotRunModel: "这台设备不支持"
        case .modelLacksLanguage(let language):
            "不支持\(language == controller.languages.spoken ? language.spokenName : language.writtenName)"
        case .noLanguagePack: "没有这两种语言的语言包"
        case .sameLanguage: "两边是同一种语言"
        case .notReported: "系统没有给出结果"
        }
    }

    /// Asks the system for the language pack of the languages in use. While a
    /// request is out, the button is off.
    private func requestLanguagePack() {
        guard packRequest == nil else { return }
        let pair = controller.languages
        requestedPair = pair
        packRequest = TranslationSession.Configuration(
            source: pair.spoken.translationLanguage, target: pair.target.translationLanguage)
    }
}

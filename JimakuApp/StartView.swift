import AVFoundation
import JimakuCore
import SwiftUI
import Translation

/// The app's one screen: a preview of the caption window, the button that starts or
/// stops a session, the settings, and the captions of the current session.
struct StartView: View {
    @State private var controller = SessionController()
    /// The language pack the user asked to download. The system shows its own
    /// sheet for it.
    @State private var packRequest: TranslationSession.Configuration?
    @Environment(\.scenePhase) private var scenePhase

    private var isRunning: Bool { controller.session.isActive }

    var body: some View {
        Form {
            Section {
                CaptionPreview(layer: controller.window.displayLayer)
                    .aspectRatio(controller.frameSize, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))

                Button {
                    controller.performPrimaryAction()
                } label: {
                    Text(primaryActionTitle)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!controller.session.canPerformPrimaryAction)
                .accessibilityIdentifier("primaryAction")

                if isRunning, let hint = audioHint {
                    HStack(spacing: 12) {
                        Text(hint)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("audioHint")
                        Spacer(minLength: 0)
                        if controller.audioStatus == .notBroadcasting {
                            BroadcastPicker()
                                .frame(width: 44, height: 44)
                                .accessibilityIdentifier("broadcastPicker")
                        }
                    }
                }

                if let notice = controller.notice {
                    Text(notice)
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("notice")
                }
            }

            Section("设置") {
                Picker("说话的语言", selection: spoken) {
                    ForEach(controller.spokenChoices) { language in
                        Text(language.spokenName).tag(language)
                    }
                }
                .disabled(isRunning)
                .accessibilityIdentifier("language")

                Picker("翻译成", selection: target) {
                    ForEach(controller.targetChoices) { language in
                        Text(language.writtenName).tag(language)
                    }
                }
                .disabled(isRunning)
                .accessibilityIdentifier("target")

                if controller.engineChoices.count > 1 {
                    Picker("翻译引擎", selection: engine) {
                        ForEach(controller.engineChoices, id: \.self) { engine in
                            switch engine {
                            case .languagePack: Text("语言包").tag(engine)
                            case .appleIntelligence: Text("Apple Intelligence").tag(engine)
                            }
                        }
                    }
                    .accessibilityIdentifier("engine")
                }

                if controller.needsLanguagePack {
                    LabeledContent("语言包还没下载") {
                        Button("下载") { requestLanguagePack() }
                            .accessibilityIdentifier("downloadLanguagePack")
                    }
                }

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
        .onChange(of: scenePhase) { _, phase in
            // A language pack may have been downloaded in the system's settings.
            if phase == .active { controller.refreshLanguageSupport() }
        }
        .translationTask(packRequest) { session in
            // Shows the system's sheet, which asks before it downloads. The
            // session is not Sendable and this call leaves the main actor; that
            // is safe because nothing else uses this session.
            nonisolated(unsafe) let unisolated = session
            try? await unisolated.prepareTranslation()
            controller.refreshLanguageSupport()
        }
    }

    private var spoken: Binding<CaptionLanguage> {
        Binding(get: { controller.languages.spoken }, set: { controller.choose(spoken: $0) })
    }

    private var target: Binding<CaptionLanguage> {
        Binding(get: { controller.languages.target }, set: { controller.choose(target: $0) })
    }

    private var engine: Binding<TranslationEngine> {
        Binding(get: { controller.activeEngine }, set: { controller.engine = $0 })
    }

    /// Asks the system for the language pack of the chosen languages. Asking for
    /// the same pair again runs the request again.
    private func requestLanguagePack() {
        let source = controller.languages.spoken.translationLanguage
        let target = controller.languages.target.translationLanguage
        if packRequest?.source == source, packRequest?.target == target {
            packRequest?.invalidate()
        } else {
            packRequest = TranslationSession.Configuration(source: source, target: target)
        }
    }

    /// What the user should know about the audio. Nil when audio is arriving.
    private var audioHint: String? {
        switch controller.audioStatus {
        case .unavailable: "读不到共享的音频缓冲，收不到别的 app 的声音。"
        case .notBroadcasting: "还没开始录屏。点右边的圆钮，选 Jimaku，开始直播。"
        case .stalled: "录屏已开始，暂时没有声音。"
        case .receiving: nil
        }
    }

    private var primaryActionTitle: String {
        switch controller.session.primaryAction {
        case .start: "开始"
        case .stop: "停止"
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

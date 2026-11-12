import AVFoundation
import JimakuCore
import SwiftUI

/// The app's one screen: a preview of the caption window, the button that starts or
/// stops a session, the settings, and the captions of the current session.
struct StartView: View {
    @State private var controller = SessionController()

    private var isRunning: Bool { controller.session.isActive }

    var body: some View {
        Form {
            Section {
                CaptionPreview(layer: controller.window.displayLayer)
                    .aspectRatio(CaptionFrameRenderer.frameSize, contentMode: .fit)
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
                Picker("说话的语言", selection: $controller.language) {
                    Text("英语").tag(SourceLanguage.english)
                    Text("日语").tag(SourceLanguage.japanese)
                }
                .disabled(isRunning)
                .accessibilityIdentifier("language")

                Picker("翻译", selection: $controller.engine) {
                    Text("语言包").tag(TranslationEngine.languagePack)
                    Text("Apple Intelligence").tag(TranslationEngine.appleIntelligence)
                }
                .accessibilityIdentifier("engine")

                Picker("显示", selection: $controller.style.mode) {
                    Text("原文和中文").tag(CaptionStyle.Mode.originalAndTranslation)
                    Text("只显示中文").tag(CaptionStyle.Mode.translationOnly)
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

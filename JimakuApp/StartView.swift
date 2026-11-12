import AVFoundation
import JimakuCore
import SwiftUI

/// The only screen so far: a preview of the caption window, one button that starts
/// or stops a session, and the system control that starts the screen broadcast.
struct StartView: View {
    @State private var controller = SessionController()

    var body: some View {
        VStack(spacing: 28) {
            CaptionPreview(layer: controller.window.displayLayer)
                .aspectRatio(CaptionFrameRenderer.frameSize, contentMode: .fit)
                .frame(maxWidth: 520)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                controller.performPrimaryAction()
            } label: {
                Text(primaryActionTitle)
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: 280)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("primaryAction")

            if controller.session.state == .running, let hint = audioHint {
                VStack(spacing: 10) {
                    Text(hint)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("audioHint")
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
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("notice")
            }
        }
        .padding()
        .onAppear { controller.prepare() }
    }

    /// What the user should know about the audio. Nil when audio is arriving.
    private var audioHint: String? {
        switch controller.audioStatus {
        case .unavailable: "读不到共享的音频缓冲，收不到别的 app 的声音。"
        case .notBroadcasting: "还没开始录屏。点下面的圆钮，选 Jimaku，开始直播。"
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

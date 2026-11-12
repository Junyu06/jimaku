import AVFoundation
import JimakuCore
import SwiftUI

/// The only screen so far: a preview of the caption window and one button that
/// starts or stops a session.
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

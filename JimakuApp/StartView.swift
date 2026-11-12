import JimakuCore
import SwiftUI

/// The only screen so far: one button that starts or stops a caption session.
/// The button does not capture or show anything yet; it only reflects session state.
struct StartView: View {
    @State private var session = CaptionSession()

    var body: some View {
        Button {
            session.performPrimaryAction()
        } label: {
            Text(primaryActionTitle)
                .font(.title2.weight(.semibold))
                .frame(maxWidth: 280)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityIdentifier("primaryAction")
        .padding()
    }

    private var primaryActionTitle: String {
        switch session.primaryAction {
        case .start: "开始"
        case .stop: "停止"
        }
    }
}

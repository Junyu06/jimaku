import SwiftUI

/// The page that says why the screen recording is needed: a title, three rows
/// (what it is for, what is not kept, when it is asked for), and one button
/// that closes it.
struct RecordingExplanationView: View {
    /// The button's title: the page stands before a session, or was asked for.
    let buttonTitle: LocalizedStringKey
    let close: () -> Void

    var body: some View {
        // Scrolls only when the text is too large for the sheet.
        ViewThatFits(in: .vertical) {
            page
            ScrollView { page }
        }
        .accessibilityIdentifier("recordingExplanation")
    }

    private var page: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 28) {
                Text("为什么要打开录屏")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                    .padding(.bottom, 8)

                row(
                    symbol: "waveform",
                    title: "拿到视频的声音",
                    detail: "我们要通过录屏拿到视频里的声音，才能出字幕。")
                row(
                    symbol: "eye.slash",
                    title: "不保存任何画面",
                    detail: "我们只用声音，画面不保存，保护你的隐私。")
                row(
                    symbol: "hand.tap",
                    title: "每次开始都要开一次",
                    detail: "点「开始」后会弹出「屏幕直播」，点里面的「开始直播」。")
            }

            Spacer(minLength: 36)

            Button(action: close) {
                Text(buttonTitle)
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("closeRecordingExplanation")
        }
        .frame(maxWidth: 460)
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
    }

    private func row(symbol: String, title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

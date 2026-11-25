import JimakuCore
import SwiftUI

/// The captions of earlier sessions: a list, newest first, and one session
/// behind each row.
struct SavedCaptionsView: View {
    let controller: SessionController

    @Environment(\.dismiss) private var dismiss
    @State private var confirmsDeletingAll = false

    private var sessions: [SavedSession] { controller.archive.sessions }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(sessions) { session in
                        NavigationLink(value: session.id) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.startedAt, format: Self.dateFormat)
                                Text(verbatim: Self.languages(of: session))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                // What tells two sessions of one day apart.
                                if let first = session.lines.first {
                                    Text(verbatim: first.original)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        // By the row's own session, not by its place in a
                        // list that a running session can change.
                        .swipeActions {
                            Button("删除", role: .destructive) { controller.deleteSaved(session.id) }
                        }
                    }
                }

                if controller.holdsSavedCaptions {
                    // At the end of the list and not in the bar, where a
                    // finger looking for a way back would find it. There
                    // also when the list is empty and a file could not be
                    // read or deleted: this deletes those too.
                    Section {
                        Button("全部删除", role: .destructive) { confirmsDeletingAll = true }
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("deleteAllSaved")
                            // On the button, so that where the system shows
                            // the question as a popover it points at it.
                            .confirmationDialog(
                                "删除全部字幕？", isPresented: $confirmsDeletingAll, titleVisibility: .visible
                            ) {
                                Button("全部删除", role: .destructive) { controller.deleteAllSaved() }
                                Button("取消", role: .cancel) {}
                            } message: {
                                Text("本机保存的字幕都会删除，无法恢复。")
                            }
                    }
                }
            }
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView("暂无字幕记录", systemImage: "captions.bubble")
                }
            }
            .navigationTitle("字幕记录")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                if let session = sessions.first(where: { $0.id == id }) {
                    SavedSessionView(session: session) { controller.deleteSaved(id) }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("savedCaptions")
    }

    static let dateFormat = Date.FormatStyle.dateTime.year().month().day().hour().minute()

    /// The two languages of a session, by the names the settings use.
    static func languages(of session: SavedSession) -> String {
        let spoken = CaptionLanguage(identifier: session.spoken)?.spokenName ?? session.spoken
        let target = CaptionLanguage(identifier: session.target)?.writtenName ?? session.target
        return "\(spoken) → \(target)"
    }
}

/// One saved session: its lines, a way to send them out as a text file, and a
/// way to delete it.
private struct SavedSessionView: View {
    let session: SavedSession
    let delete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var confirmsDeleting = false

    var body: some View {
        List {
            ForEach(Array(session.lines.enumerated()), id: \.offset) { _, line in
                VStack(alignment: .leading, spacing: 4) {
                    Text(line.original)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    if let translation = line.translation {
                        Text(translation)
                    }
                }
                .textSelection(.enabled)
            }
        }
        .navigationTitle(Text(session.startedAt, format: SavedCaptionsView.dateFormat))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(role: .destructive) {
                    confirmsDeleting = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
                .accessibilityIdentifier("deleteSaved")
                .confirmationDialog("删除这次字幕？", isPresented: $confirmsDeleting, titleVisibility: .visible) {
                    Button("删除", role: .destructive) {
                        delete()
                        dismiss()
                    }
                    Button("取消", role: .cancel) {}
                }

                ShareLink(item: SavedSessionText(session: session), preview: SharePreview(session.fileName())) {
                    Label("导出", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("exportSaved")
            }
        }
    }
}

/// One row of the caption window, laid out in lines.
public struct CaptionRow: Equatable, Sendable {
    public enum Role: Equatable, Sendable {
        /// The row the reader follows. Drawn large and bright.
        case primary
        /// Supporting text. Drawn smaller and dimmer.
        case secondary
    }

    /// The lines that have text, top to bottom. At most `lineCount`.
    public var lines: [CaptionLine]
    public var role: Role
    /// How many columns fit on a line. The text size follows from this.
    public var columns: Int
    /// How many lines the row has room for.
    public var lineCount: Int

    public init(lines: [CaptionLine], role: Role, columns: Int, lineCount: Int) {
        self.lines = lines
        self.role = role
        self.columns = columns
        self.lineCount = lineCount
    }
}

/// What the caption window shows.
public enum CaptionContent: Equatable, Sendable {
    /// Caption rows, top to bottom.
    case rows([CaptionRow])
    /// One line saying what the session is waiting for.
    case notice(String)
}

/// Which rows the caption window has and how much fits on them.
public struct CaptionLayout: Equatable, Sendable {
    public struct Row: Equatable, Sendable {
        public var columns: Int
        public var lines: Int
        public var role: CaptionRow.Role
        /// How wide characters are in the font this row is drawn with.
        public var widths: GlyphWidths

        public init(columns: Int, lines: Int, role: CaptionRow.Role, widths: GlyphWidths = .estimated) {
            self.columns = columns
            self.lines = lines
            self.role = role
            self.widths = widths
        }
    }

    /// The row for what was said. Nil when it is not shown.
    public var original: Row?
    /// The row for the translation. Nil when it is not shown.
    public var translation: Row?

    public init(original: Row?, translation: Row?) {
        self.original = original
        self.translation = translation
    }

    /// The layout for a style. On the main row twenty-seven, twenty-three, or twenty wide
    /// characters fit a line at the small, medium, and large size. The main row has as many lines as the
    /// style asks for; `CaptionFrame` makes the frame tall enough for them.
    ///
    /// Rows start with estimated character widths; whoever draws them sets the
    /// measured widths of its font.
    ///
    /// - Parameter translationAvailable: when translation cannot run, the original
    ///   takes the main row, whatever the display mode.
    public init(style: CaptionStyle, translationAvailable: Bool = true) {
        let (mainColumns, sideColumns) =
            switch style.textSize {
            case .small: (54, 76)
            case .medium: (46, 66)
            case .large: (40, 60)
            }
        let main = Row(columns: mainColumns, lines: style.lines, role: .primary)
        if !translationAvailable {
            self.init(original: main, translation: nil)
        } else if style.mode == .translationOnly {
            self.init(original: nil, translation: main)
        } else {
            self.init(original: Row(columns: sideColumns, lines: 1, role: .secondary), translation: main)
        }
    }
}

/// What the caption window shows for a transcript. The original row fills line
/// by line and rolls up; it ends with the speech in progress as tentative text.
/// The translation row shows finished translations only and fills like a page:
/// when the next translation does not fit in what is left, a new page begins
/// with it. While speech is waiting to be translated the row ends with a
/// waiting mark, if there is room.
///
/// On the original row every sentence starts on a new line. Translations follow
/// one another on a line with a gap between them. A translation longer than a
/// whole page is shown from its beginning; `showMore()` turns to the rest.
///
/// The board only ever adds to what it shows. A translation that arrives after a
/// later one is already on the row is left out of the window; putting it in the
/// middle would move text the reader may be reading. It is still in the transcript.
public struct CaptionBoard: Equatable, Sendable {
    public private(set) var layout: CaptionLayout

    private var originalRow: RollingRow?
    private var translationRow: RollingRow?
    /// Entries before these indices have been dealt with on each row.
    private var nextOriginal = 0
    private var nextTranslation = 0

    /// Counts up whenever the translation row turns to something new to read: a
    /// new translation, or the next lines of a long one. Whoever times the pages
    /// of a long translation starts over when this changes, and only then.
    public private(set) var page = 0

    /// Shown at the end of the translation row while speech is waiting to be
    /// translated.
    public static let waitingMark = "…"

    /// How many recent entries are laid out again when the layout changes: as
    /// many as the tallest row has lines.
    private static let recall = CaptionStyle.lineChoices.max() ?? 2

    public init(layout: CaptionLayout) {
        self.layout = layout
        originalRow = layout.original.map {
            RollingRow(columns: $0.columns, lines: $0.lines, textsApart: true, widths: $0.widths)
        }
        // The waiting mark never gets a line of its own.
        translationRow = layout.translation.map {
            RollingRow(
                columns: $0.columns, lines: $0.lines, pages: true, gap: true, tentativeWraps: false,
                widths: $0.widths)
        }
    }

    /// Takes in what is new in `transcript` since the last call. A board follows
    /// one transcript from its start; a new or reset transcript needs a new board.
    ///
    /// - Parameter translating: whether kept speech is waiting to be translated
    ///   or being translated now. With speech in progress, it decides whether
    ///   the waiting mark is shown.
    public mutating func show(_ transcript: Transcript, translating: Bool = false) {
        let entries = transcript.entries
        if entries.count < max(nextOriginal, nextTranslation) {
            // Not the transcript this board was following. Start over rather than
            // read past its end.
            self = CaptionBoard(layout: layout)
        }

        originalRow?.update(appending: entries[nextOriginal...].map(\.original), tentative: transcript.pending)
        nextOriginal = entries.count

        var translations: [String] = []
        if let newest = entries[nextTranslation...].lastIndex(where: { $0.translation != nil }) {
            translations = entries[nextTranslation...newest].compactMap(\.translation)
            nextTranslation = newest + 1
        }
        let isWaiting = !transcript.pending.isEmpty || translating
        translationRow?.update(appending: translations, tentative: isWaiting ? Self.waitingMark : "")
        if !translations.isEmpty { page += 1 }
    }

    /// Whether the newest translation is longer than its row and the rest of it
    /// has not been shown yet.
    public var hasMore: Bool { translationRow?.hasMore ?? false }

    /// How long a page of the translation row should stay before `showMore()`
    /// turns it, in seconds: a second and a quarter for each line it has.
    public var pageTime: Double {
        1.25 * Double((layout.translation ?? layout.original)?.lines ?? 2)
    }

    /// Shows the next lines of a translation that is longer than its row. Whoever
    /// owns the board calls this once the reader has had time for the lines shown.
    public mutating func showMore() {
        guard hasMore else { return }
        translationRow?.showMore()
        page += 1
    }

    /// Changes the layout and lays the most recent captions out again.
    public mutating func relay(_ layout: CaptionLayout, showing transcript: Transcript, translating: Bool = false) {
        let page = page
        self = CaptionBoard(layout: layout)
        // Laid out again, the translation row starts a page of its own.
        self.page = page + 1
        let start = max(transcript.entries.count - Self.recall, 0)
        nextOriginal = start
        nextTranslation = start
        show(transcript, translating: translating)
    }

    /// The rows of the layout, top to bottom, each with the lines it shows now.
    public var rows: [CaptionRow] {
        var rows: [CaptionRow] = []
        if let row = layout.original, let content = originalRow {
            rows.append(CaptionRow(lines: content.visible, role: row.role, columns: row.columns, lineCount: row.lines))
        }
        if let row = layout.translation, let content = translationRow {
            rows.append(CaptionRow(lines: content.visible, role: row.role, columns: row.columns, lineCount: row.lines))
        }
        return rows
    }

    /// True when no row has anything to show.
    public var isEmpty: Bool {
        rows.allSatisfy { $0.lines.isEmpty }
    }

    /// Lays out one caption pair on its own, for the preview before a session.
    public static func rows(for lines: CaptionLines, layout: CaptionLayout) -> [CaptionRow] {
        var board = CaptionBoard(layout: layout)
        board.originalRow?.append(lines.original)
        board.translationRow?.append(lines.translation)
        return board.rows
    }
}

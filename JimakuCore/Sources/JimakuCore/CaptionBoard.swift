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

    /// The layout for a style. The numbers are what fits the caption frame: a wide
    /// character on the main row is a twelfth of the width at medium size.
    ///
    /// Rows start with estimated character widths; whoever draws them sets the
    /// measured widths of its font.
    ///
    /// - Parameter translationAvailable: when translation cannot run, the original
    ///   takes the main row, whatever the display mode.
    public init(style: CaptionStyle, translationAvailable: Bool = true) {
        let (mainColumns, sideColumns) =
            switch style.textSize {
            case .small: (30, 52)
            case .medium: (24, 46)
            case .large: (22, 42)
            }
        let alone = style.mode == .translationOnly || !translationAvailable
        let main = Row(columns: mainColumns, lines: alone && style.textSize == .small ? 3 : 2, role: .primary)
        if !translationAvailable {
            self.init(original: main, translation: nil)
        } else if style.mode == .translationOnly {
            self.init(original: nil, translation: main)
        } else {
            self.init(original: Row(columns: sideColumns, lines: 1, role: .secondary), translation: main)
        }
    }
}

/// What the caption window shows for a transcript: each row filling line by line
/// and rolling up, with the speech in progress as tentative text at its end.
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

    /// How many recent entries are laid out again when the layout changes.
    private static let recall = 4

    public init(layout: CaptionLayout) {
        self.layout = layout
        originalRow = layout.original.map { RollingRow(columns: $0.columns, lines: $0.lines, widths: $0.widths) }
        // The provisional translation is a preview and the part of it most likely to
        // change is its end, so only one line's worth of its beginning is shown.
        translationRow = layout.translation.map {
            RollingRow(columns: $0.columns, lines: $0.lines, tentativeLimit: $0.columns, widths: $0.widths)
        }
    }

    /// Takes in what is new in `transcript` since the last call. A board follows
    /// one transcript from its start; a new or reset transcript needs a new board.
    public mutating func show(_ transcript: Transcript) {
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
        translationRow?.update(appending: translations, tentative: transcript.pendingTranslation ?? "")
    }

    /// Changes the layout and lays the most recent captions out again.
    public mutating func relay(_ layout: CaptionLayout, showing transcript: Transcript) {
        self = CaptionBoard(layout: layout)
        let start = max(transcript.entries.count - Self.recall, 0)
        nextOriginal = start
        nextTranslation = start
        show(transcript)
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

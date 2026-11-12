/// One line of a caption row: text that will not change, followed by text that
/// still may.
public struct CaptionLine: Equatable, Sendable {
    public var settled: String
    public var tentative: String

    public init(settled: String, tentative: String = "") {
        self.settled = settled
        self.tentative = tentative
    }

    public var text: String { settled + tentative }
}

/// A caption row of fixed lines that fills like a page and rolls up.
///
/// Text is only ever added at the end. A line that is full never changes again:
/// when a new line is needed and the row is full, the oldest line leaves and the
/// others move up by one. So a reader's eye never has to chase text sideways, which
/// is what makes a caption that slides with every new character hard to read.
///
/// Text that may still change is tentative: it is laid out after the settled text
/// and replaced as a whole. A row can be told not to give tentative text a line
/// of its own; it is then left out when it does not fit after the settled text.
///
/// A row can keep its texts apart: each text added then starts on a new line, the
/// way a subtitle shows one sentence at a time. Tentative text that may take
/// lines of its own counts as a text and starts a new line as well; tentative
/// text that may not, such as a mark, stays at the end of the last line. Such a
/// row rolls a whole text off at a time, so it never shows the end of a text
/// whose beginning is gone, unless the newest text alone is longer than the row.
/// Of such a text the row shows the end, or, if it is told to page, the
/// beginning first and the rest when `showMore()` is called.
public struct RollingRow: Equatable, Sendable {
    public let columns: Int
    public let lines: Int
    /// Whether each text added starts on a new line.
    public let textsApart: Bool
    /// Whether a text longer than the row is shown from its beginning, a page at
    /// a time. Only for rows that keep texts apart.
    public let pages: Bool
    /// Whether tentative text may run on to further lines, rolling the row if
    /// need be. If not, tentative text that does not fit on the line being filled
    /// is not shown.
    public let tentativeWraps: Bool
    /// How wide characters are in the font the row is drawn with.
    public let widths: GlyphWidths

    /// The most recent full lines, oldest first. Only as many as can be shown.
    private var closed: [String] = []
    /// How many lines have been filled since the row was created.
    private var closedCount = 0
    /// The settled text on the line being filled.
    private var open = ""
    private var tentative = ""
    /// How many lines have rolled off the top.
    private var rolledOff = 0
    /// The lines on which the most recent texts began, when texts are kept apart.
    private var starts: [Int] = []

    public init(
        columns: Int, lines: Int, textsApart: Bool = false, pages: Bool = false, tentativeWraps: Bool = true,
        widths: GlyphWidths = .estimated
    ) {
        self.columns = max(columns, 2)
        self.lines = max(lines, 1)
        self.textsApart = textsApart
        self.pages = pages && textsApart
        self.tentativeWraps = tentativeWraps
        self.widths = widths
    }

    /// Adds text that will not change any more.
    public mutating func append(_ text: String) {
        update(appending: [text], tentative: tentative)
    }

    /// Replaces the text that may still change. Empty removes it.
    public mutating func setTentative(_ text: String) {
        update(appending: [], tentative: text)
    }

    /// Adds settled text and replaces the tentative text in one step. The row
    /// rolls for the result only, not for the new settled text next to the old
    /// tentative text it usually takes the place of.
    public mutating func update(appending texts: [String], tentative: String) {
        for text in texts.map(\.trimmed) where !text.isEmpty {
            if textsApart {
                if !open.isEmpty {
                    closed.append(open)
                    closedCount += 1
                    open = ""
                }
                starts.append(closedCount)
            }
            // The line being filled keeps what is on it: the new text is its own
            // group, so a mark at its start cannot take a character down with it.
            let cells =
                open.map { CaptionText.Cell(character: $0, isTentative: false, group: 0) }
                + (Self.joiner(between: open, and: text) + text).map {
                    CaptionText.Cell(character: $0, isTentative: false, group: 1)
                }
            var wrapped = CaptionText.wrap(cells, columns: columns, widths: widths).map {
                String($0.map(\.character))
            }
            open = wrapped.popLast() ?? ""
            closed.append(contentsOf: wrapped)
            closedCount += wrapped.count
        }
        starts.removeFirst(max(starts.count - lines, 0))
        self.tentative = tentative.trimmed
        roll()
    }

    /// Whether settled text below the lines shown is waiting for its turn. Only
    /// a row that pages ever has such text.
    public var hasMore: Bool {
        pages && closedCount + openLines.count - lines > rolledOff
    }

    /// Rolls on to the next lines of a text that is longer than the row, by a
    /// whole page or as far as its end.
    public mutating func showMore() {
        guard hasMore else { return }
        rolledOff = min(rolledOff + lines, closedCount + openLines.count - lines)
        forget()
    }

    /// The lines to show now, top to bottom. At most `lines`.
    public var visible: [CaptionLine] {
        let inProgress = openLines
        let total = closedCount + inProgress.count
        return (rolledOff..<total).prefix(lines).map { index in
            if index < closedCount {
                return CaptionLine(settled: closed[closed.count - (closedCount - index)])
            }
            let cells = inProgress[index - closedCount]
            return CaptionLine(
                settled: String(cells.filter { !$0.isTentative }.map(\.character)),
                tentative: String(cells.filter(\.isTentative).map(\.character))
            )
        }
    }

    public var isEmpty: Bool { closedCount == 0 && open.isEmpty && tentative.isEmpty }

    /// The line being filled and whatever the tentative text adds after it.
    private var openLines: [[CaptionText.Cell]] {
        let settled = open.map { CaptionText.Cell(character: $0, isTentative: false, group: 0) }
        if tentativeIsApart {
            let own = tentative.map { CaptionText.Cell(character: $0, isTentative: true, group: 2) }
            return [settled] + CaptionText.wrap(own, columns: columns, widths: widths)
        }
        let added = (Self.joiner(between: open, and: tentative) + tentative).map {
            CaptionText.Cell(character: $0, isTentative: true, group: 2)
        }
        let withTentative = CaptionText.wrap(settled + added, columns: columns, widths: widths)
        if tentativeWraps || withTentative.count <= 1 { return withTentative }
        return CaptionText.wrap(settled, columns: columns, widths: widths)
    }

    /// Whether the tentative text is laid out as a text of its own.
    private var tentativeIsApart: Bool {
        textsApart && tentativeWraps && !open.isEmpty && !tentative.isEmpty
    }

    /// Rolls to where the row should be for what it holds now.
    ///
    /// A row whose texts run on rolls far enough to show the newest line and does
    /// not roll back, with one exception: when tentative text that had rolled it
    /// is withdrawn and nothing would be left to show, the last line comes back.
    ///
    /// A row that keeps texts apart starts at the beginning of the oldest text
    /// that still fits whole with everything after it. That follows from what
    /// the row holds, so it comes back when tentative text shrinks or goes. A
    /// page turned with `showMore()` stays turned while its text is the newest.
    private mutating func roll() {
        let total = closedCount + openLines.count
        let end = max(total - lines, 0)
        defer { forget() }
        guard textsApart else {
            rolledOff = min(max(rolledOff, end), max(total - 1, 0))
            return
        }
        var target = end
        let beginnings = starts + (tentativeIsApart ? [closedCount + 1] : [])
        if let beginning = beginnings.filter({ $0 >= end }).min() {
            target = beginning
        } else if pages, let newest = starts.last {
            // The newest text alone is longer than the row: begin at its start,
            // or stay on the page already turned to.
            target = rolledOff > newest && rolledOff <= end ? rolledOff : newest
        }
        rolledOff = min(target, max(total - 1, 0))
    }

    /// Drops the full lines the row cannot come back to. It can come back when
    /// tentative text shrinks or goes: by fewer lines than it shows, or, if it
    /// pages, to the start of the newest text.
    private mutating func forget() {
        var earliest = rolledOff
        if pages, let newest = starts.last { earliest = min(earliest, newest) }
        let needed = max(closedCount - earliest, 0) + lines
        closed.removeFirst(max(closed.count - needed, 0))
    }

    /// A space goes between two pieces only where both sides are narrow
    /// characters, so English gets spaces and Japanese or Chinese does not.
    private static func joiner(between first: String, and second: String) -> String {
        guard let last = first.last, let next = second.first,
            CaptionText.width(of: String(last)) == 1, CaptionText.width(of: String(next)) == 1
        else { return "" }
        return " "
    }
}

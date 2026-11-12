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
public struct RollingRow: Equatable, Sendable {
    public let columns: Int
    public let lines: Int
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

    public init(columns: Int, lines: Int, tentativeWraps: Bool = true, widths: GlyphWidths = .estimated) {
        self.columns = max(columns, 2)
        self.lines = max(lines, 1)
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
        closed.removeFirst(max(closed.count - lines, 0))
        self.tentative = tentative.trimmed
        roll()
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
        let added = (Self.joiner(between: open, and: tentative) + tentative).map {
            CaptionText.Cell(character: $0, isTentative: true, group: 2)
        }
        let withTentative = CaptionText.wrap(settled + added, columns: columns, widths: widths)
        if tentativeWraps || withTentative.count <= 1 { return withTentative }
        return CaptionText.wrap(settled, columns: columns, widths: widths)
    }

    /// Rolls far enough to show the newest line. A row does not roll back, with
    /// one exception: when tentative text that had rolled it is withdrawn and
    /// nothing would be left to show, the last line comes back.
    private mutating func roll() {
        let total = closedCount + openLines.count
        rolledOff = min(max(rolledOff, total - lines), max(total - 1, 0))
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

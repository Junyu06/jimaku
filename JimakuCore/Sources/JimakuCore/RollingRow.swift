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
/// whose beginning is gone, unless the newest text alone is longer than the row;
/// of such a text it shows the end.
///
/// A row can page instead of rolling. It then fills from the top like a page.
/// A text that does not fit in what is left of the page starts a new page, and
/// nothing of the old page stays, so text that is on the page never moves. A
/// text longer than a whole page is shown from its beginning, and the rest a
/// page at a time when `showMore()` is called. Tentative text gets no line of
/// its own in such a row.
///
/// Texts that follow one another on a line can have a gap between them.
public struct RollingRow: Equatable, Sendable {
    public let columns: Int
    public let lines: Int
    /// Whether each text added starts on a new line.
    public let textsApart: Bool
    /// Whether the row fills like a page and turns to a new one when a text does
    /// not fit, instead of rolling.
    public let pages: Bool
    /// Whether texts that follow one another on a line have a gap between them,
    /// as wide as a wide character, so a reader can tell where one ends.
    public let gap: Bool
    /// Whether tentative text may run on to further lines, rolling the row if
    /// need be. If not, tentative text that does not fit on the line being filled
    /// is not shown. Never in a row that pages.
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
    /// The first line of the page that text is being added to, in a row that
    /// pages. The page shown, `rolledOff`, is this one or an earlier page of a
    /// text that runs over several.
    private var pageStart = 0

    public init(
        columns: Int, lines: Int, textsApart: Bool = false, pages: Bool = false, gap: Bool = false,
        tentativeWraps: Bool = true, widths: GlyphWidths = .estimated
    ) {
        self.columns = max(columns, 2)
        self.lines = max(lines, 1)
        self.textsApart = textsApart
        self.pages = pages
        self.gap = gap
        self.tentativeWraps = tentativeWraps && !pages
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
                closeOpenLine()
                starts.append(closedCount)
            }
            var wrapped = wrap(text, after: open)
            if pages, !open.isEmpty, closedCount + wrapped.count - pageStart > lines {
                // Run on from the line being filled, the text would not fit in
                // what is left of the page. It starts on a line of its own, and
                // that line is the top of a new page.
                closeOpenLine()
                wrapped = wrap(text, after: "")
            }
            let beginning = closedCount
            open = wrapped.popLast() ?? ""
            closed.append(contentsOf: wrapped)
            closedCount += wrapped.count
            if pages {
                let end = closedCount + (open.isEmpty ? 0 : 1)
                // A text that does not fit in what is left of the page starts a
                // new one.
                if end - pageStart > lines { pageStart = beginning }
                // The page on which the newest text begins is the one to show.
                rolledOff = pageStart
                // A text longer than a page runs on; what follows it goes on the
                // page where it ends.
                while end - pageStart > lines { pageStart += lines }
            }
        }
        starts.removeFirst(max(starts.count - lines, 0))
        self.tentative = tentative.trimmed
        roll()
    }

    /// Ends the line being filled, if there is anything on it.
    private mutating func closeOpenLine() {
        guard !open.isEmpty else { return }
        closed.append(open)
        closedCount += 1
        open = ""
    }

    /// The lines that `line` and `text` after it make. The line keeps what is on
    /// it: the new text is its own group, so a mark at its start cannot take a
    /// character down with it.
    private func wrap(_ text: String, after line: String) -> [String] {
        let cells =
            line.map { CaptionText.Cell(character: $0, isTentative: false, group: 0) }
            + (joiner(between: line, and: text) + text).map {
                CaptionText.Cell(character: $0, isTentative: false, group: 1)
            }
        return CaptionText.wrap(cells, columns: columns, widths: widths).map { String($0.map(\.character)) }
    }

    /// Whether settled text below the lines shown is waiting for its turn. Only
    /// a row that pages ever has such text: the rest of a text longer than a page.
    public var hasMore: Bool {
        pages && closedCount + openLines.count - lines > rolledOff
    }

    /// Turns to the next page of a text that is longer than a page.
    public mutating func showMore() {
        guard hasMore else { return }
        rolledOff += lines
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
        let added = (Self.space(between: open, and: tentative) + tentative).map {
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
    /// the row holds, so it comes back when tentative text shrinks or goes.
    ///
    /// A row that pages does not roll: its page is chosen when text is added
    /// and when `showMore()` is called.
    private mutating func roll() {
        let total = closedCount + openLines.count
        let end = max(total - lines, 0)
        defer { forget() }
        guard !pages else { return }
        guard textsApart else {
            rolledOff = min(max(rolledOff, end), max(total - 1, 0))
            return
        }
        var target = end
        let beginnings = starts + (tentativeIsApart ? [closedCount + 1] : [])
        if let beginning = beginnings.filter({ $0 >= end }).min() { target = beginning }
        rolledOff = min(target, max(total - 1, 0))
    }

    /// Drops the full lines the row cannot come back to. A rolling row can come
    /// back, when tentative text shrinks or goes, by fewer lines than it shows.
    /// A row that pages never goes back before the page it shows.
    private mutating func forget() {
        let needed = max(closedCount - rolledOff, 0) + lines
        closed.removeFirst(max(closed.count - needed, 0))
    }

    /// What goes between a line and a text that follows on it. With a gap: two
    /// spaces between narrow characters; one space after a wide mark, which has
    /// blank space of its own; otherwise an ideographic space. Without a gap,
    /// what `space(between:and:)` gives.
    private func joiner(between first: String, and second: String) -> String {
        guard gap, let last = first.last, let next = second.first else {
            return Self.space(between: first, and: second)
        }
        let lastIsWide = CaptionText.width(of: String(last)) == 2
        if !lastIsWide, CaptionText.width(of: String(next)) == 1 { return "  " }
        if lastIsWide, !CaptionText.isSpoken(last) { return " " }
        return "\u{3000}"
    }

    /// A space goes between two pieces only where both sides are narrow
    /// characters, so English gets spaces and Japanese or Chinese does not.
    private static func space(between first: String, and second: String) -> String {
        guard let last = first.last, let next = second.first,
            CaptionText.width(of: String(last)) == 1, CaptionText.width(of: String(next)) == 1
        else { return "" }
        return " "
    }
}

/// How wide characters are, in columns, for breaking text into lines.
///
/// A wide character such as a Chinese or Japanese one is two columns. Narrow
/// characters differ a lot in a proportional font: "W" is nearly two columns and
/// "i" half of one. Counting each as one is good enough to estimate, but lines
/// broken by estimate can come out wider than the row, so the app measures the
/// font it draws with and passes the result in.
public struct GlyphWidths: Equatable, Sendable {
    /// Measured widths of narrow characters, in columns.
    public var narrow: [Character: Double]
    /// The width of a narrow character that was not measured.
    public var unknownNarrow: Double

    public init(narrow: [Character: Double] = [:], unknownNarrow: Double = 1) {
        self.narrow = narrow
        self.unknownNarrow = unknownNarrow
    }

    /// Every narrow character one column.
    public static let estimated = GlyphWidths()

    public func width(of character: Character) -> Double {
        CaptionText.width(of: character) == 2 ? 2 : narrow[character] ?? unknownNarrow
    }
}

extension CaptionText {
    /// One character of a caption row.
    struct Cell: Equatable, Sendable {
        var character: Character
        var isTentative: Bool
        /// Cells that arrived together. Characters of different groups are never
        /// tied into one unit, so text that arrives later cannot pull a character
        /// that is already shown onto another line.
        var group = 0
    }

    /// Breaks `text` into lines of at most `columns` columns.
    ///
    /// Chinese and Japanese break between any two characters, English between
    /// words. A mark that closes a phrase stays with the character before it, so it
    /// does not start a line, unless the two together do not fit on a line. A word
    /// longer than a line is broken inside.
    ///
    /// The one way a line can be wider than `columns` is a single character that
    /// is: it gets a line to itself. Widths are expected to be finite and positive,
    /// and `columns` below 2 is treated as 2.
    public static func wrap(_ text: String, columns: Int, widths: GlyphWidths = .estimated) -> [String] {
        wrap(text.map { Cell(character: $0, isTentative: false) }, columns: columns, widths: widths)
            .map { String($0.map(\.character)) }
    }

    static func wrap(_ cells: [Cell], columns: Int, widths: GlyphWidths = .estimated) -> [[Cell]] {
        let columns = Double(max(columns, 2))
        var lines: [[Cell]] = []
        var line: [Cell] = []
        var lineWidth = 0.0
        var space: [Cell] = []

        func width(_ cells: [Cell]) -> Double { cells.reduce(0) { $0 + widths.width(of: $1.character) } }
        func endLine() {
            lines.append(line)
            line = []
            lineWidth = 0
        }

        for unit in units(of: cells) {
            if unit[0].character.isWhitespace {
                // A space is only kept between two units on the same line.
                if !line.isEmpty { space = unit }
                continue
            }
            let unitWidth = width(unit)
            if lineWidth + width(space) + unitWidth <= columns {
                line += space + unit
                lineWidth += width(space) + unitWidth
            } else {
                if !line.isEmpty { endLine() }
                // A unit wider than a whole line is broken wherever the line is
                // full, but not right before a mark that closes it.
                for (index, cell) in unit.enumerated() {
                    let cellWidth = widths.width(of: cell.character)
                    if lineWidth + cellWidth > columns, !line.isEmpty {
                        // Take the character before a closing mark along, if the
                        // two fit on a line together.
                        var carried: [Cell] = []
                        if index > 0, closes(cell.character), line.count > 1, let last = line.last,
                            widths.width(of: last.character) + cellWidth <= columns
                        {
                            line.removeLast()
                            carried = [last]
                        }
                        endLine()
                        line = carried
                        lineWidth = width(carried)
                    }
                    line.append(cell)
                    lineWidth += cellWidth
                }
            }
            space = []
        }
        if !line.isEmpty { lines.append(line) }
        return lines
    }

    /// Groups cells into the units a line break may not split: a run of spaces, a
    /// word of narrow letters, or a single wide character, each with the marks
    /// that open or close it.
    private static func units(of cells: [Cell]) -> [[Cell]] {
        var units: [[Cell]] = []
        var joinsNext = false
        for cell in cells {
            let character = cell.character
            if character.isWhitespace {
                if let last = units.last, last[0].character.isWhitespace {
                    units[units.count - 1].append(cell)
                } else {
                    units.append([cell])
                }
                joinsNext = false
                continue
            }
            var attaches = false
            if let previous = units.last?.last, !previous.character.isWhitespace, previous.group == cell.group {
                if joinsNext {
                    // After an opening mark.
                    attaches = true
                } else if isSpoken(character) {
                    // Narrow letters continue the word before them.
                    attaches =
                        isWordCharacter(character)
                        && (isWordCharacter(previous.character) || isNarrowJoiner(previous.character))
                } else {
                    // A closing mark stays with what it closes.
                    attaches = closes(character)
                }
            }
            if attaches {
                units[units.count - 1].append(cell)
            } else {
                units.append([cell])
            }
            joinsNext = openers.contains(character)
        }
        return units
    }

    /// Whether a character is a mark that belongs to what comes before it.
    private static func closes(_ character: Character) -> Bool {
        !isSpoken(character) && !character.isWhitespace && !openers.contains(character)
    }

    /// Marks that sit inside a narrow word, as in "it's" or "well-known".
    static func isNarrowJoiner(_ character: Character) -> Bool {
        character == "'" || character == "’" || character == "-"
    }
}

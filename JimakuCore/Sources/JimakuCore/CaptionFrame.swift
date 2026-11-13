/// The picture the caption window shows: how large it is and how much room its
/// rows take. Sizes are in pixels.
///
/// The frame is as wide as ever and at least `minimumHeight` high. A layout with
/// more lines than fit in that gets a taller frame, so the text keeps its size
/// and the window grows instead.
public enum CaptionFrame {
    public static let width = 1200.0
    public static let minimumHeight = 400.0

    /// Space left clear along each edge.
    public static let padding = 40.0
    /// Space between two rows, and between the rows and the meter.
    public static let rowSpacing = 10.0
    /// The height of the audio meter along the bottom. Its space is set aside
    /// whether or not it is drawn.
    public static let meterHeight = 10.0
    /// The share of the nominal size the font is drawn at, leaving a little slack
    /// at the end of a full line.
    public static let fill = 0.985
    /// Line height as a multiple of the font size.
    public static let leading = 1.4

    /// The width captions are drawn in.
    public static var textWidth: Double { width - padding * 2 }

    /// The font size at which `columns` columns fill the text width: a wide
    /// character is as wide as the font size, and takes two columns.
    public static func fontSize(columns: Int) -> Double {
        textWidth * 2 / Double(max(columns, 2)) * fill
    }

    /// How high the rows of `layout` are together, with every line they have
    /// room for.
    public static func rowsHeight(for layout: CaptionLayout) -> Double {
        let rows = [layout.original, layout.translation].compactMap { $0 }
        let lines = rows.reduce(0) { $0 + Double($1.lines) * fontSize(columns: $1.columns) * leading }
        return lines + rowSpacing * Double(max(rows.count - 1, 0))
    }

    /// How much of a frame's height is left for rows.
    public static func rowsArea(inFrameOfHeight height: Double) -> Double {
        height - padding * 2 - meterHeight - rowSpacing
    }

    /// The height of the frame for `layout`: `minimumHeight`, or as much more as
    /// its rows need, to the next even pixel.
    public static func height(for layout: CaptionLayout) -> Double {
        let needed = rowsHeight(for: layout) + padding * 2 + meterHeight + rowSpacing
        return max(minimumHeight, (needed / 2).rounded(.up) * 2)
    }
}

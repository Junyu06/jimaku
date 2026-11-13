/// How captions look in the floating window.
public struct CaptionStyle: Equatable, Sendable {
    public enum TextSize: String, CaseIterable, Equatable, Sendable {
        case small
        case medium
        case large
    }

    public enum Mode: String, CaseIterable, Equatable, Sendable {
        /// The original line above its translation.
        case originalAndTranslation
        /// The translation alone.
        case translationOnly
    }

    /// How many lines the main row may have.
    public static let lineChoices = [2, 3, 4]

    public var textSize: TextSize
    public var mode: Mode
    /// How many lines the main row has: the translation, or the original when
    /// it stands in for it. Kept within `lineChoices`.
    public var lines: Int {
        didSet { lines = Self.clamped(lines) }
    }

    public init(textSize: TextSize = .medium, mode: Mode = .originalAndTranslation, lines: Int = 2) {
        self.textSize = textSize
        self.mode = mode
        self.lines = Self.clamped(lines)
    }

    private static func clamped(_ lines: Int) -> Int {
        min(max(lines, lineChoices[0]), lineChoices[lineChoices.count - 1])
    }
}

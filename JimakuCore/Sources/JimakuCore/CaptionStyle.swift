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

    public var textSize: TextSize
    public var mode: Mode

    public init(textSize: TextSize = .medium, mode: Mode = .originalAndTranslation) {
        self.textSize = textSize
        self.mode = mode
    }
}

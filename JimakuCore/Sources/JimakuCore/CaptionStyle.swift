/// How captions look in the floating window.
public struct CaptionStyle: Equatable, Sendable {
    public enum TextSize: String, CaseIterable, Equatable, Sendable {
        case small
        case medium
        case large

        /// Factor applied to the caption font sizes.
        public var scale: Double {
            switch self {
            case .small: 0.8
            case .medium: 1
            case .large: 1.25
            }
        }
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

extension CaptionLines {
    /// The rows to draw in a given display mode, top to bottom.
    public func rows(in mode: CaptionStyle.Mode) -> [CaptionRow] {
        switch mode {
        case .originalAndTranslation:
            rows
        case .translationOnly:
            CaptionLines(original: "", translation: translation).rows
        }
    }
}

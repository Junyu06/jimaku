/// The text of one caption: what was said, and what it means.
public struct CaptionLines: Equatable, Sendable {
    public var original: String
    public var translation: String

    public init(original: String, translation: String) {
        self.original = original
        self.translation = translation
    }

    /// The rows to draw, top to bottom.
    ///
    /// The translation is the row the reader is here for, so it is primary. The
    /// original sits above it as a smaller secondary row. When only one of the two
    /// has text, that one is drawn alone as the primary row.
    public var rows: [CaptionRow] {
        let original = self.original.trimmed
        let translation = self.translation.trimmed
        switch (original.isEmpty, translation.isEmpty) {
        case (true, true):
            return []
        case (false, true):
            return [CaptionRow(text: original, role: .primary)]
        case (true, false):
            return [CaptionRow(text: translation, role: .primary)]
        case (false, false):
            return [
                CaptionRow(text: original, role: .secondary),
                CaptionRow(text: translation, role: .primary),
            ]
        }
    }
}

/// One row of text in the caption window.
public struct CaptionRow: Equatable, Sendable {
    public enum Role: Equatable, Sendable {
        /// The row the reader follows. Drawn large and bright.
        case primary
        /// Supporting text. Drawn smaller and dimmer.
        case secondary
    }

    public var text: String
    public var role: Role

    public init(text: String, role: Role) {
        self.text = text
        self.role = role
    }
}

extension String {
    /// The string without leading and trailing whitespace and newlines.
    var trimmed: String {
        var view = self[...]
        while let first = view.first, first.isWhitespace { view = view.dropFirst() }
        while let last = view.last, last.isWhitespace { view = view.dropLast() }
        return String(view)
    }
}

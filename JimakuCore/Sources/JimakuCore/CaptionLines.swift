/// A caption pair: what was said, and what it means.
public struct CaptionLines: Equatable, Sendable {
    public var original: String
    public var translation: String

    public init(original: String, translation: String) {
        self.original = original
        self.translation = translation
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

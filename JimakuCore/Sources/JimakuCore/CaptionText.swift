/// Fits text to the width of a caption row.
public enum CaptionText {
    /// How much room `text` takes, in columns: a wide character such as a Chinese or
    /// Japanese one takes two, everything else takes one.
    public static func width(of text: String) -> Int {
        text.reduce(0) { $0 + width(of: $1) }
    }

    /// The end of `text` that fits in `width` columns, marked with a leading ellipsis
    /// when the beginning was cut.
    ///
    /// Live speech grows at the end, so the end is the part worth showing. Text with
    /// spaces is cut between words; text without them is cut between characters.
    public static func tail(of text: String, width limit: Int) -> String {
        guard width(of: text) > limit else { return text }

        // One column is reserved for the ellipsis.
        var remaining = limit - 1
        var start = text.endIndex
        while start > text.startIndex {
            let previous = text.index(before: start)
            let needed = width(of: text[previous])
            if needed > remaining { break }
            remaining -= needed
            start = previous
        }
        var kept = text[start...]

        // If the cut landed inside a word and there are later words, drop the fragment.
        let cutInsideWord =
            start > text.startIndex
            && !text[text.index(before: start)].isWhitespace
            && !(kept.first?.isWhitespace ?? true)
        if cutInsideWord, let space = kept.firstIndex(where: \.isWhitespace) {
            kept = kept[space...]
        }
        return "…" + String(kept).trimmed
    }

    private static func width(of character: Character) -> Int {
        guard let scalar = character.unicodeScalars.first?.value else { return 0 }
        switch scalar {
        case 0x1100...0x115F,  // Hangul Jamo
            0x2E80...0xA4CF,  // CJK radicals, kana, CJK ideographs, Yi
            0xAC00...0xD7A3,  // Hangul syllables
            0xF900...0xFAFF,  // CJK compatibility ideographs
            0xFE30...0xFE4F,  // CJK compatibility forms
            0xFF00...0xFF60,  // Fullwidth forms
            0xFFE0...0xFFE6,
            0x1F300...0x1FAFF,  // Emoji
            0x20000...0x3FFFF:  // CJK extensions
            return 2
        default:
            return 1
        }
    }
}

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
    ///
    /// Surrounding whitespace is ignored. A width that leaves no room returns nothing.
    public static func tail(of text: String, width limit: Int) -> String {
        let text = text.trimmed
        guard width(of: text) > limit else { return text }
        guard limit > 0 else { return "" }

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

        // If the cut landed inside a word, drop the fragment. Only narrow characters
        // form words that way; Chinese and Japanese text can be cut anywhere.
        if start > text.startIndex, let first = kept.first,
            isWordCharacter(text[text.index(before: start)]), isWordCharacter(first)
        {
            let fragmentEnd = kept.firstIndex(where: { !isWordCharacter($0) }) ?? kept.endIndex
            // Keep the fragment when it is all there is.
            if fragmentEnd < kept.endIndex {
                kept = kept[fragmentEnd...]
            }
        }
        return "…" + String(kept).trimmed
    }

    /// Splits text into the sentences that have finished and the unfinished rest.
    ///
    /// Live speech can run for a long time before the recognizer calls any of it
    /// final. A sentence that has reached its ending mark is unlikely to change, so
    /// it can be treated as settled without waiting.
    ///
    /// - Returns: the finished sentences, the unfinished rest, and `consumed`: how
    ///   many characters of `text` the finished sentences took, including the
    ///   whitespace after the last one.
    public static func sentences(in text: String) -> (complete: [String], remainder: String, consumed: Int) {
        let characters = Array(text)
        var complete: [String] = []
        var start = 0
        var index = 0
        while index < characters.count {
            guard endsSentence(characters, at: index) else {
                index += 1
                continue
            }
            // Keep repeated ending marks and closing quotes with the sentence.
            var end = index + 1
            while end < characters.count, endings.contains(characters[end]) || closers.contains(characters[end]) {
                end += 1
            }
            let sentence = String(characters[start..<end]).trimmed
            if !sentence.isEmpty { complete.append(sentence) }
            while end < characters.count, characters[end].isWhitespace {
                end += 1
            }
            start = end
            index = end
        }
        return (complete, String(characters[start...]).trimmed, complete.isEmpty ? 0 : start)
    }

    private static let endings: Set<Character> = ["。", "！", "？", "!", "?", "．", "｡", "."]
    private static let closers: Set<Character> = ["」", "』", "”", "’", "\"", "'", "）", ")"]

    /// Words that are followed by a period without ending a sentence.
    private static let abbreviations: Set<String> = [
        "mr", "mrs", "ms", "dr", "st", "prof", "sr", "jr", "vs", "etc", "no", "mt",
    ]

    private static func endsSentence(_ characters: [Character], at index: Int) -> Bool {
        let character = characters[index]
        guard endings.contains(character) else { return false }
        guard character == "." else { return true }

        let previous: Character? = index >= 1 ? characters[index - 1] : nil
        let next: Character? = index + 1 < characters.count ? characters[index + 1] : nil

        // Periods in a row are a pause ("Wait... maybe"), not an ending.
        if previous == "." || next == "." { return false }

        // A period ends a sentence only when something other than text follows it,
        // which rules out "3.5" and the first period of "U.S.".
        if let next, !(next.isWhitespace || closers.contains(next) || endings.contains(next)) {
            return false
        }
        // At the very end, a period after a digit may be a decimal point whose
        // digits have not been spoken yet.
        if next == nil, let previous, previous.isNumber { return false }

        // The word before the period: an initial ("S." of "U.S.") or a title ("Dr.").
        var wordStart = index
        while wordStart > 0, characters[wordStart - 1].isLetter {
            wordStart -= 1
        }
        let word = String(characters[wordStart..<index]).lowercased()
        if word.count == 1 {
            let beforeWord: Character = wordStart >= 1 ? characters[wordStart - 1] : " "
            if beforeWord.isWhitespace || beforeWord == "." { return false }
        }
        if abbreviations.contains(word) { return false }
        return true
    }

    static func isWordCharacter(_ character: Character) -> Bool {
        width(of: character) == 1 && (character.isLetter || character.isNumber)
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

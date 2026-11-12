/// Measures caption text and tells where a sentence ends. Cutting speech into
/// pieces is in CaptionText+Chunks.swift, breaking text into lines in
/// CaptionText+Wrap.swift.
public enum CaptionText {
    /// How much room `text` takes, in columns: a wide character such as a Chinese or
    /// Japanese one takes two, everything else takes one.
    public static func width(of text: String) -> Int {
        text.reduce(0) { $0 + width(of: $1) }
    }

    static let endings: Set<Character> = ["。", "！", "？", "!", "?", "．", "｡", "."]
    static let closers: Set<Character> = ["」", "』", "”", "’", "\"", "'", "）", ")"]

    /// Words that are followed by a period without ending a sentence.
    private static let abbreviations: Set<String> = [
        "mr", "mrs", "ms", "dr", "st", "prof", "sr", "jr", "vs", "etc", "no", "mt",
    ]

    /// Whether the character at `index` ends a sentence.
    static func endsSentence(_ characters: [Character], at index: Int) -> Bool {
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

    static func width(of character: Character) -> Int {
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

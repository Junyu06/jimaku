/// How speech is cut into the pieces that get translated.
public struct ChunkRules: Equatable, Sendable {
    /// A clause mark such as a comma cuts only after at least this many columns.
    public var clauseMinimum: Int

    /// Speech that runs on without a mark is cut once it is this many columns wide.
    public var limit: Int

    public init(clauseMinimum: Int, limit: Int) {
        self.clauseMinimum = clauseMinimum
        self.limit = limit
    }

    /// About three seconds of Japanese at most, and no cut after only a word or two.
    public static let japanese = ChunkRules(clauseMinimum: 12, limit: 36)

    /// About a dozen English words at most.
    public static let english = ChunkRules(clauseMinimum: 20, limit: 60)
}

extension SourceLanguage {
    public var chunkRules: ChunkRules {
        switch self {
        case .english: .english
        case .japanese: .japanese
        }
    }
}

extension CaptionText {
    /// Whether a character is something that was said, as opposed to punctuation or
    /// spacing. The recognizer keeps changing its mind about punctuation long after
    /// it has settled on the words, so positions in speech are counted in these.
    public static func isSpoken(_ character: Character) -> Bool {
        character.isLetter || character.isNumber
    }

    public static func spokenCount(in text: String) -> Int {
        text.reduce(0) { $0 + (isSpoken($1) ? 1 : 0) }
    }

    /// `text` without its first `count` spoken characters, and without the marks
    /// and spaces that close them. A mark that opens what comes next is kept.
    public static func dropping(spoken count: Int, from text: String) -> String {
        guard count > 0 else { return text.trimmed }
        var remaining = count
        var index = text.startIndex
        while index < text.endIndex, remaining > 0 {
            if isSpoken(text[index]) { remaining -= 1 }
            index = text.index(after: index)
        }
        guard remaining == 0 else { return "" }
        while index < text.endIndex, !isSpoken(text[index]), !openers.contains(text[index]) {
            index = text.index(after: index)
        }
        return String(text[index...]).trimmed
    }

    /// Cuts pieces off the front of `text`, each a sentence, a clause, or a run of
    /// words short enough to translate and show at once.
    ///
    /// Only text that will not change any more may be cut. A piece ends at a
    /// sentence ending, at a clause mark once enough has been said, or, when speech
    /// runs on without marks, where a new word starts.
    ///
    /// - Parameters:
    ///   - stableSpoken: how many spoken characters at the front of `text` are
    ///     stable. Marks that close them count as stable too.
    ///   - isComplete: nothing will be added to `text`, so all of it is stable and
    ///     its end ends a piece.
    /// - Returns: the pieces, the text left over, and how many spoken characters
    ///   the pieces took.
    public static func chunks(
        in text: String,
        stableSpoken: Int,
        isComplete: Bool,
        rules: ChunkRules
    ) -> (chunks: [String], rest: String, spoken: Int) {
        let characters = Array(text)
        let stableEnd = isComplete ? characters.count : endOfStable(characters, spoken: stableSpoken)

        var chunks: [String] = []
        var start = 0
        while true {
            while start < stableEnd, characters[start].isWhitespace { start += 1 }
            guard start < stableEnd else { break }

            let mark = nextMarkedEnd(characters, from: start, rules: rules)
            let cut: Int
            if let mark, width(characters[start..<mark]) <= rules.limit + rules.clauseMinimum {
                // A marked end is near. If it is not stable yet, wait for it rather
                // than cut just before it.
                guard mark <= stableEnd else { break }
                cut = mark
            } else if width(characters[start..<stableEnd]) >= rules.limit,
                let soft = unmarkedEnd(characters, from: start, to: stableEnd, rules: rules)
            {
                cut = soft
            } else if let mark, mark <= stableEnd {
                cut = mark
            } else if isComplete {
                cut = characters.count
            } else {
                break
            }

            let piece = String(characters[start..<cut]).trimmed
            if piece.contains(where: isSpoken) { chunks.append(piece) }
            start = cut
        }

        let spoken = characters[..<start].reduce(0) { $0 + (isSpoken($1) ? 1 : 0) }
        return (chunks, String(characters[start...]).trimmed, spoken)
    }

    /// Marks that open what comes after them.
    static let openers: Set<Character> = ["「", "『", "（", "(", "“", "‘", "[", "【", "《", "〈"]

    private static let clauseMarks: Set<Character> = ["、", "，", ",", "；", ";", "：", ":"]

    /// The index just past the stable part of `characters`.
    private static func endOfStable(_ characters: [Character], spoken: Int) -> Int {
        guard spoken > 0 else { return 0 }
        var remaining = spoken
        var index = 0
        while index < characters.count, remaining > 0 {
            if isSpoken(characters[index]) { remaining -= 1 }
            index += 1
        }
        while index < characters.count, !isSpoken(characters[index]), !openers.contains(characters[index]) {
            index += 1
        }
        return index
    }

    /// The index just past the first sentence ending or usable clause mark at or
    /// after `start`, wherever it is, stable or not.
    private static func nextMarkedEnd(_ characters: [Character], from start: Int, rules: ChunkRules) -> Int? {
        var index = start
        while index < characters.count {
            if endsSentence(characters, at: index) {
                // Keep repeated ending marks and closing quotes with the sentence.
                var end = index + 1
                while end < characters.count, endings.contains(characters[end]) || closers.contains(characters[end]) {
                    end += 1
                }
                return end
            }
            if endsClause(characters, at: index), width(characters[start..<index]) >= rules.clauseMinimum {
                return index + 1
            }
            index += 1
        }
        return nil
    }

    private static func endsClause(_ characters: [Character], at index: Int) -> Bool {
        let character = characters[index]
        guard clauseMarks.contains(character) else { return false }
        if width(of: character) == 2 { return true }
        // A narrow mark ends a clause only before a space, which rules out the
        // comma in "1,000" and the colon in "10:30".
        guard index + 1 < characters.count else { return true }
        return characters[index + 1].isWhitespace
    }

    /// Where to cut speech that runs on without a mark: within the limit, the last
    /// place where a joining word such as "and" starts, else the last place where
    /// any word starts; failing both, the first word start after the limit. Text
    /// with no word start at all is cut at the limit once it is twice as long.
    private static func unmarkedEnd(
        _ characters: [Character],
        from start: Int,
        to stableEnd: Int,
        rules: ChunkRules
    ) -> Int? {
        var best: Int?
        var bestJoining: Int?
        var atLimit: Int?
        // The width of the piece a cut at the current index would make, which
        // does not count the spaces just before the cut.
        var columns = 0
        var spaces = 0
        let last = min(stableEnd, characters.count - 1)
        guard start + 1 <= last else { return nil }
        for index in (start + 1)...last {
            let previous = characters[index - 1]
            if previous.isWhitespace {
                spaces += width(of: previous)
            } else {
                columns += spaces + width(of: previous)
                spaces = 0
            }
            if atLimit == nil, columns >= rules.limit { atLimit = index }
            guard startsWord(characters, at: index) else { continue }
            if columns > rules.limit {
                return bestJoining ?? best ?? index
            }
            if columns >= rules.clauseMinimum {
                best = index
                if startsJoiningWord(characters, at: index) { bestJoining = index }
            }
        }
        if let cut = bestJoining ?? best { return cut }
        if width(characters[start..<stableEnd]) >= rules.limit * 2 { return atLimit }
        return nil
    }

    /// English words that usually begin a new clause.
    private static let joiningWords: Set<String> = [
        "and", "but", "or", "so", "because", "that", "which", "who", "when", "where", "while", "if", "then",
        "although", "though", "since",
    ]

    private static func startsJoiningWord(_ characters: [Character], at index: Int) -> Bool {
        var end = index
        while end < characters.count, isWordCharacter(characters[end]) { end += 1 }
        return joiningWords.contains(String(characters[index..<end]).lowercased())
    }

    /// Whether a new word starts at `index`, as far as that can be told without a
    /// dictionary: after a space or a mark, where the script changes between narrow
    /// and wide, and in Japanese where kanji or katakana follow hiragana.
    private static func startsWord(_ characters: [Character], at index: Int) -> Bool {
        let previous = characters[index - 1]
        let next = characters[index]
        if next.isWhitespace { return false }
        if previous.isWhitespace { return true }
        // "it's" and "well-known" are one word each.
        if isNarrowJoiner(previous), index >= 2, isWordCharacter(characters[index - 2]), isWordCharacter(next) {
            return false
        }
        if !isSpoken(next) { return openers.contains(next) && !openers.contains(previous) }
        if !isSpoken(previous) { return !openers.contains(previous) }

        switch (script(of: previous), script(of: next)) {
        case (.narrow, .narrow): return false
        case (.narrow, _), (_, .narrow): return true
        case (.hiragana, .kanji), (.hiragana, .katakana): return true
        case (.katakana, .kanji), (.kanji, .katakana): return true
        default: return false
        }
    }

    private enum Script {
        case narrow, hiragana, katakana, kanji, otherWide
    }

    private static func script(of character: Character) -> Script {
        guard width(of: character) == 2, let scalar = character.unicodeScalars.first?.value else { return .narrow }
        switch scalar {
        case 0x3040...0x309F: return .hiragana
        case 0x30A0...0x30FF, 0x31F0...0x31FF: return .katakana
        case 0x3005, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF, 0x20000...0x3FFFF: return .kanji
        default: return .otherWide
        }
    }

    private static func width(_ characters: ArraySlice<Character>) -> Int {
        characters.reduce(0) { $0 + width(of: $1) }
    }
}

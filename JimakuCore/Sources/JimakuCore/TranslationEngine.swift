/// What does the translating.
public enum TranslationEngine: String, CaseIterable, Equatable, Sendable {
    /// The system's downloaded translation language packs.
    case languagePack
    /// The on-device Apple Intelligence model.
    case appleIntelligence
}

/// What to say to a language model to get a caption translated, and how to tidy up
/// what it says back.
public enum TranslationPrompt {
    public static func instructions(from language: SourceLanguage) -> String {
        let source =
            switch language {
            case .english: "English"
            case .japanese: "Japanese"
            }
        return """
            You translate live video captions from \(source) into Simplified Chinese.
            Reply with the Simplified Chinese translation only: no quotation marks, no notes, \
            no explanations, and none of the original text.
            Keep it short and natural, the way a subtitle reads.
            The text comes from speech recognition, so it may contain mistakes or be cut off; \
            translate what is there.
            """
    }

    /// Reduces a model's reply to the translation itself: models sometimes add a
    /// label, wrap the answer in quotes, or append a note.
    public static func clean(_ response: String) -> String {
        var text = response.replacing("\r\n", with: "\n").trimmed

        // A leading label, possibly on a line of its own.
        for label in labels where text.hasPrefix(label) {
            text = String(text.dropFirst(label.count)).trimmed
            break
        }

        // Anything after a blank line is commentary, not the translation.
        if let paragraphEnd = text.firstRange(of: "\n\n") {
            text = String(text[..<paragraphEnd.lowerBound]).trimmed
        }

        // A caption is one line.
        text = text.split(separator: "\n").map { String($0).trimmed }.joined(separator: " ")

        for (opening, closing) in quotePairs
        where text.count >= 2 && text.first == opening && text.last == closing {
            let inner = text.dropFirst().dropLast()
            if !inner.contains(opening) && !inner.contains(closing) {
                text = String(inner).trimmed
            }
            break
        }
        return text
    }

    private static let labels = ["翻译：", "翻译:", "译文：", "译文:", "Translation:", "translation:"]

    private static let quotePairs: [(Character, Character)] = [
        ("“", "”"), ("\"", "\""), ("「", "」"), ("『", "』"), ("‘", "’"), ("'", "'"),
    ]
}

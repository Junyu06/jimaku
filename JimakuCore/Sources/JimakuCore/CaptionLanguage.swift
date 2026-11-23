import Foundation

/// A language captions can be made from or translated into.
///
/// The list is fixed: these are the languages that both the system speech
/// recognizer and the system translation know, as measured on macOS 27.2. What
/// a given device can do with them is in `LanguageSupport`.
public struct CaptionLanguage: Hashable, Sendable, Identifiable {
    /// The language as the translator knows it, such as "en" or "zh-Hans".
    public let identifier: String

    /// The locale to ask the speech recognizer for. Nil for a language that is
    /// only translated into.
    public let recognizerLocale: String?

    /// What to call the language when instructing a language model.
    public let englishName: String

    /// Whether the language is written in wide characters, as Japanese is.
    let isWide: Bool

    public var id: String { identifier }

    public var canBeSpoken: Bool { recognizerLocale != nil }

    /// The language without its script. Two languages of one family are two
    /// written forms of the same language, and are not translated into each
    /// other.
    public var family: String {
        String(identifier.prefix { $0 != "-" })
    }

    /// How speech in this language is cut into the pieces that get translated.
    /// The rules were tuned on Japanese and English. A language written in wide
    /// characters takes the Japanese ones and any other the English ones: the
    /// numbers count columns, and in both groups a column is about as much
    /// speech.
    public var chunkRules: ChunkRules { isWide ? .japanese : .english }

    public static let english = CaptionLanguage("en", recognizer: "en-US", name: "English")
    public static let japanese = CaptionLanguage("ja", recognizer: "ja-JP", name: "Japanese", isWide: true)
    /// Spoken, this is Mandarin; the recognizer writes it in simplified characters
    /// whatever the speaker's region.
    public static let simplifiedChinese = CaptionLanguage(
        "zh-Hans", recognizer: "zh-CN", name: "Simplified Chinese", isWide: true)
    public static let traditionalChinese = CaptionLanguage(
        "zh-Hant", recognizer: nil, name: "Traditional Chinese", isWide: true)
    public static let korean = CaptionLanguage("ko", recognizer: "ko-KR", name: "Korean", isWide: true)
    public static let spanish = CaptionLanguage("es", recognizer: "es-ES", name: "Spanish")
    public static let french = CaptionLanguage("fr", recognizer: "fr-FR", name: "French")
    public static let german = CaptionLanguage("de", recognizer: "de-DE", name: "German")
    public static let italian = CaptionLanguage("it", recognizer: "it-IT", name: "Italian")
    public static let portuguese = CaptionLanguage("pt", recognizer: "pt-BR", name: "Portuguese")
    public static let hindi = CaptionLanguage("hi", recognizer: "hi-IN", name: "Hindi")

    /// Every language, in the order they are offered.
    public static let all: [CaptionLanguage] = [
        .english, .japanese, .simplifiedChinese, .traditionalChinese, .korean,
        .spanish, .french, .german, .italian, .portuguese, .hindi,
    ]

    /// The language with this identifier, if the app has it.
    public init?(identifier: String) {
        guard let known = Self.all.first(where: { $0.identifier == identifier }) else { return nil }
        self = known
    }

    private init(_ identifier: String, recognizer: String?, name: String, isWide: Bool = false) {
        self.identifier = identifier
        self.recognizerLocale = recognizer
        self.englishName = name
        self.isWide = isWide
    }

    /// The first of the device's preferred languages that the app has. The
    /// identifiers are the system's, such as "zh-Hans-CN" or "en-GB".
    public static func preferred(among identifiers: [String]) -> CaptionLanguage? {
        for identifier in identifiers {
            let language = Locale.Language(identifier: identifier)
            guard let code = language.languageCode?.identifier else { continue }
            if code == "zh" {
                // A region stands in for a script that is not written out:
                // "zh-TW" is traditional.
                let script = Locale.Language(identifier: language.maximalIdentifier).script?.identifier
                return script == "Hant" ? .traditionalChinese : .simplifiedChinese
            }
            if let match = all.first(where: { $0.family == code }) { return match }
        }
        return nil
    }
}

/// The two languages of a session: the one spoken and the one captions are
/// translated into.
public struct LanguagePair: Hashable, Sendable {
    public var spoken: CaptionLanguage
    public var target: CaptionLanguage

    public init(spoken: CaptionLanguage, target: CaptionLanguage) {
        self.spoken = spoken
        self.target = target
    }

    /// Whether one of the two can be translated into the other at all.
    public var isTranslatable: Bool { spoken.family != target.family }

    /// The pair with another target. Choosing the spoken language as the target
    /// swaps the two, so the pair stays one that can be translated.
    public func choosing(target new: CaptionLanguage) -> LanguagePair {
        var pair = LanguagePair(spoken: spoken, target: new)
        if !pair.isTranslatable { pair.spoken = Self.spokenLanguage(insteadOf: target, awayFrom: new) }
        return pair
    }

    /// The pair with another spoken language. Choosing the target as the spoken
    /// language swaps the two.
    public func choosing(spoken new: CaptionLanguage) -> LanguagePair {
        var pair = LanguagePair(spoken: new, target: target)
        if !pair.isTranslatable {
            pair.target =
                spoken.family != new.family
                ? spoken : CaptionLanguage.all.first { $0.family != new.family } ?? target
        }
        return pair
    }

    /// The pair to start with.
    ///
    /// - Parameters:
    ///   - spoken: the stored identifier of the spoken language, if any.
    ///   - target: the stored identifier of the target, if any.
    ///   - legacySpoken: what a version that knew only English and Japanese
    ///     stored for the spoken language. That version always translated into
    ///     Simplified Chinese, and still does after an update.
    ///   - preferred: the device's preferred languages, most wanted first. With
    ///     nothing stored, captions are translated into the first the app has.
    public static func restored(
        spoken: String?,
        target: String?,
        legacySpoken: String?,
        preferred: [String]
    ) -> LanguagePair {
        let legacy: CaptionLanguage? =
            switch legacySpoken {
            case "english": .english
            case "japanese": .japanese
            default: nil
            }
        let target =
            target.flatMap(CaptionLanguage.init(identifier:))
            ?? (legacy == nil ? CaptionLanguage.preferred(among: preferred) : .simplifiedChinese)
            ?? .english
        let stored = spoken.flatMap(CaptionLanguage.init(identifier:)) ?? legacy
        if let stored, stored.canBeSpoken, stored.family != target.family {
            return LanguagePair(spoken: stored, target: target)
        }
        return LanguagePair(spoken: spokenLanguage(insteadOf: .english, awayFrom: target), target: target)
    }

    /// `wanted` if it can be spoken and translated into `target`; otherwise the
    /// first language that can. English and Japanese come first in the list, so
    /// that is one of those two.
    private static func spokenLanguage(insteadOf wanted: CaptionLanguage, awayFrom target: CaptionLanguage) -> CaptionLanguage {
        if wanted.canBeSpoken, wanted.family != target.family { return wanted }
        return CaptionLanguage.all.first { $0.canBeSpoken && $0.family != target.family } ?? wanted
    }
}

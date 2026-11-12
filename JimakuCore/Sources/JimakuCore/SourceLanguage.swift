/// The language being spoken in what the user is watching. The user picks it; the
/// app does not detect it.
public enum SourceLanguage: String, CaseIterable, Equatable, Sendable {
    case english
    case japanese

    /// The locale to ask the speech recognizer for.
    public var localeIdentifier: String {
        switch self {
        case .english: "en-US"
        case .japanese: "ja-JP"
        }
    }

    /// The language to translate from.
    public var languageCode: String {
        switch self {
        case .english: "en"
        case .japanese: "ja"
        }
    }
}

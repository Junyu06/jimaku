import Foundation
import FoundationModels
import JimakuCore

enum AppleIntelligenceError: LocalizedError {
    case deviceNotEligible
    case notEnabled
    case modelNotReady
    case unavailable
    case languageNotSupported(CaptionLanguage)

    var errorDescription: String? {
        switch self {
        case .deviceNotEligible: "这台设备不支持 Apple Intelligence。"
        case .notEnabled: "系统设置里还没打开 Apple Intelligence。"
        case .modelNotReady: "Apple Intelligence 的模型还在下载或准备中。"
        case .unavailable: "Apple Intelligence 现在用不了。"
        case .languageNotSupported(let language): "Apple Intelligence 不支持\(language.writtenName)。"
        }
    }
}

/// Translation with the on-device Apple Intelligence model. Nothing leaves the device.
@MainActor
final class AppleIntelligenceSource: TranslatorSource {
    func prepare(for languages: LanguagePair) async throws -> any PreparedTranslator {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            for language in [languages.spoken, languages.target]
            where !model.supportsLocale(Locale(identifier: language.identifier)) {
                throw AppleIntelligenceError.languageNotSupported(language)
            }
            return AppleIntelligenceTranslator(languages: languages)
        case .unavailable(.deviceNotEligible):
            throw AppleIntelligenceError.deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            throw AppleIntelligenceError.notEnabled
        case .unavailable(.modelNotReady):
            throw AppleIntelligenceError.modelNotReady
        case .unavailable:
            throw AppleIntelligenceError.unavailable
        }
    }
}

@MainActor
private final class AppleIntelligenceTranslator: PreparedTranslator {
    private let languages: LanguagePair

    init(languages: LanguagePair) {
        self.languages = languages
    }

    func translate(_ text: String) async throws -> String {
        // A fresh session per sentence keeps the model's small context window from
        // filling up over a long video.
        let session = LanguageModelSession(
            instructions: TranslationPrompt.instructions(from: languages.spoken, to: languages.target))
        let response = try await session.respond(to: text)
        return TranslationPrompt.clean(response.content)
    }
}

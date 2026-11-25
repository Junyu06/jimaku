import Foundation
import FoundationModels
import JimakuCore

enum AppleIntelligenceError: LocalizedError {
    case deviceNotEligible
    case notEnabled
    case modelNotReady
    case unavailable
    case languageNotSupported(CaptionLanguage)
    /// The model would not translate a sentence, though it works.
    case refused

    var errorDescription: String? {
        switch self {
        case .deviceNotEligible: String(localized: "这台设备不支持 Apple Intelligence。")
        case .notEnabled: String(localized: "系统设置里还没打开 Apple Intelligence。")
        case .modelNotReady: String(localized: "Apple Intelligence 的模型还在下载或准备中。")
        case .unavailable: String(localized: "Apple Intelligence 现在用不了。")
        case .languageNotSupported(let language): String(localized: "Apple Intelligence 不支持\(language.writtenName)。")
        case .refused: String(localized: "Apple Intelligence 没有翻译这一句。")
        }
    }
}

/// Translation with the on-device Apple Intelligence model. Nothing leaves the device.
@MainActor
final class AppleIntelligenceSource: TranslatorSource {
    /// The model as it is asked to translate. Its default guardrails turn
    /// sentences down for what they are about, a death in a war, say. The
    /// system has other guardrails for turning text into other text, and
    /// translating is that. See
    /// `docs/pitfalls/the-on-device-model-refuses-to-translate-sentences-its-default-guardrails-object-to.md`.
    static var model: SystemLanguageModel {
        SystemLanguageModel(guardrails: .permissiveContentTransformations)
    }

    func prepare(for languages: LanguagePair) async throws -> any PreparedTranslator {
        let model = Self.model
        switch model.availability {
        case .available:
            for language in [languages.spoken, languages.target]
            where !model.supportsLocale(Locale(identifier: language.identifier)) {
                throw AppleIntelligenceError.languageNotSupported(language)
            }
            return AppleIntelligenceTranslator(model: model, languages: languages)
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
    private let model: SystemLanguageModel
    private let languages: LanguagePair

    init(model: SystemLanguageModel, languages: LanguagePair) {
        self.model = model
        self.languages = languages
    }

    func translate(_ text: String) async throws -> String {
        // A fresh session per sentence keeps the model's small context window from
        // filling up over a long video.
        let session = LanguageModelSession(
            model: model,
            instructions: TranslationPrompt.instructions(from: languages.spoken, to: languages.target))
        do {
            let response = try await session.respond(to: text)
            return TranslationPrompt.clean(response.content)
        } catch {
            // The system's own description of a refusal is in English and
            // speaks of safety; the user is told only that this sentence was
            // not translated.
            throw Self.isRefusal(error) ? AppleIntelligenceError.refused : error
        }
    }

    /// Whether the model turned the sentence down, rather than failed. Which
    /// error type says so depends on the system the app runs on.
    private static func isRefusal(_ error: any Error) -> Bool {
        if #available(iOS 27.0, *), let error = error as? LanguageModelError {
            switch error {
            case .guardrailViolation, .refusal: return true
            default: return false
            }
        }
        if let error = error as? LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation, .refusal: return true
            default: return false
            }
        }
        return false
    }
}

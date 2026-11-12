import Foundation
import FoundationModels
import JimakuCore

enum AppleIntelligenceError: LocalizedError {
    case deviceNotEligible
    case notEnabled
    case modelNotReady
    case unavailable

    var errorDescription: String? {
        let reason =
            switch self {
            case .deviceNotEligible: "这台设备不支持 Apple Intelligence"
            case .notEnabled: "系统设置里还没打开 Apple Intelligence"
            case .modelNotReady: "Apple Intelligence 的模型还在下载或准备中"
            case .unavailable: "Apple Intelligence 现在用不了"
            }
        return "\(reason)。可以把「翻译」换成语言包。"
    }
}

/// Translation with the on-device Apple Intelligence model. Nothing leaves the device.
@MainActor
final class AppleIntelligenceSource: TranslatorSource {
    func prepare(from language: SourceLanguage) async throws -> any PreparedTranslator {
        switch SystemLanguageModel.default.availability {
        case .available:
            return AppleIntelligenceTranslator(language: language)
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
    private let language: SourceLanguage

    init(language: SourceLanguage) {
        self.language = language
    }

    func translate(_ text: String) async throws -> String {
        // A fresh session per sentence keeps the model's small context window from
        // filling up over a long video.
        let session = LanguageModelSession(instructions: TranslationPrompt.instructions(from: language))
        let response = try await session.respond(to: text)
        return TranslationPrompt.clean(response.content)
    }
}

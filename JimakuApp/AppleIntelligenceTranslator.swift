import FoundationModels
import JimakuCore

/// Translation with the on-device Apple Intelligence model. Nothing leaves the device.
@MainActor
final class AppleIntelligenceTranslator: Translating {
    private var language: SourceLanguage = .english

    func prepare(from language: SourceLanguage) async throws {
        self.language = language
        if case .unavailable(let reason) = SystemLanguageModel.default.availability {
            throw AppleIntelligenceError.unavailable(String(describing: reason))
        }
    }

    func translate(_ text: String) async throws -> String {
        // A fresh session per sentence keeps the model's small context window from
        // filling up over a long video.
        let session = LanguageModelSession(instructions: TranslationPrompt.instructions(from: language))
        let response = try await session.respond(to: text)
        return TranslationPrompt.clean(response.content)
    }
}

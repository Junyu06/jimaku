import Foundation
import JimakuCore
import Translation

/// Turns settled speech into the target language.
@MainActor
protocol Translating: AnyObject {
    /// Gets ready to translate from `language`. Throws when translation cannot run,
    /// with a message the user can act on.
    func prepare(from language: SourceLanguage) async throws

    func translate(_ text: String) async throws -> String
}

enum TranslationSetupError: LocalizedError {
    case languagePackMissing(SourceLanguage)
    case languagePairNotSupported
    case notPrepared

    var errorDescription: String? {
        switch self {
        case .languagePackMissing(let language):
            let name = language == .english ? "英语" : "日语"
            return "翻译语言包还没下载。到系统的 设置 → App → 翻译 → 下载的语言 里，下载\(name)和简体中文。"
        case .languagePairNotSupported:
            return "系统翻译不支持这两种语言之间的翻译。"
        case .notPrepared:
            return "翻译还没准备好。"
        }
    }
}

/// Translation with the system's downloaded language packs. Nothing leaves the device.
@MainActor
final class LanguagePackTranslator: Translating {
    private var session: TranslationSession?

    func prepare(from language: SourceLanguage) async throws {
        session = nil
        let source = Locale.Language(identifier: language.languageCode)
        let target = Locale.Language(identifier: TargetLanguage.identifier)
        switch await LanguageAvailability().status(from: source, to: target) {
        case .installed:
            session = TranslationSession(installedSource: source, target: target)
        case .supported:
            throw TranslationSetupError.languagePackMissing(language)
        case .unsupported:
            throw TranslationSetupError.languagePairNotSupported
        @unknown default:
            throw TranslationSetupError.languagePairNotSupported
        }
    }

    func translate(_ text: String) async throws -> String {
        guard let session else { throw TranslationSetupError.notPrepared }
        // TranslationSession is not Sendable and runs off the main actor. That is safe
        // here because SessionController translates one sentence at a time.
        nonisolated(unsafe) let unisolated = session
        return try await unisolated.translate(text).targetText
    }
}

#if targetEnvironment(simulator)
    /// The simulator has no translation language packs, so this looks sentences up in
    /// the demo script. Simulator only.
    @MainActor
    final class ScriptedTranslator: Translating {
        func prepare(from language: SourceLanguage) async throws {}

        func translate(_ text: String) async throws -> String {
            try? await Task.sleep(for: .milliseconds(400))
            return DemoCaptions.script.first { $0.original == text }?.translation ?? "（演示翻译）"
        }
    }
#endif

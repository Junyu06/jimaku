import Foundation
import JimakuCore
import Translation

/// Something that can translate into the target language right now.
///
/// A prepared translator belongs to the session and settings it was prepared for.
/// It holds its own configuration, so preparing another one never changes it.
@MainActor
protocol PreparedTranslator: AnyObject {
    func translate(_ text: String) async throws -> String
}

/// A way of translating: checks that it can run and hands out a translator.
@MainActor
protocol TranslatorSource: AnyObject {
    /// Throws when translation cannot run, with a message the user can act on.
    func prepare(from language: SourceLanguage) async throws -> any PreparedTranslator
}

enum TranslationSetupError: LocalizedError {
    case languagePackMissing(SourceLanguage)
    case languagePairNotSupported

    var errorDescription: String? {
        switch self {
        case .languagePackMissing(let language):
            let name = language == .english ? "英语" : "日语"
            return "翻译语言包还没下载。到系统的 设置 → App → 翻译 → 下载的语言 里，下载\(name)和简体中文。"
        case .languagePairNotSupported:
            return "系统翻译不支持这两种语言之间的翻译。"
        }
    }
}

/// Translation with the system's downloaded language packs. Nothing leaves the device.
@MainActor
final class LanguagePackSource: TranslatorSource {
    func prepare(from language: SourceLanguage) async throws -> any PreparedTranslator {
        let source = Locale.Language(identifier: language.languageCode)
        let target = Locale.Language(identifier: TargetLanguage.identifier)
        switch await LanguageAvailability().status(from: source, to: target) {
        case .installed:
            return LanguagePackTranslator(session: TranslationSession(installedSource: source, target: target))
        case .supported:
            throw TranslationSetupError.languagePackMissing(language)
        case .unsupported:
            throw TranslationSetupError.languagePairNotSupported
        @unknown default:
            throw TranslationSetupError.languagePairNotSupported
        }
    }
}

@MainActor
private final class LanguagePackTranslator: PreparedTranslator {
    private let session: TranslationSession

    init(session: TranslationSession) {
        self.session = session
    }

    func translate(_ text: String) async throws -> String {
        // TranslationSession is not Sendable and runs off the main actor. That is safe
        // here because the translation pipeline translates one sentence at a time.
        nonisolated(unsafe) let unisolated = session
        return try await unisolated.translate(text).targetText
    }
}

#if targetEnvironment(simulator)
    /// The simulator has no translation language packs, so this looks pieces of
    /// the demo speech up in its prepared translation. Simulator only.
    @MainActor
    final class ScriptedSource: TranslatorSource, PreparedTranslator {
        private var speech: [CaptionLines] = []

        func prepare(from language: SourceLanguage) async throws -> any PreparedTranslator {
            speech = DemoCaptions.speech(in: language)
            return self
        }

        func translate(_ text: String) async throws -> String {
            try? await Task.sleep(for: .milliseconds(150))
            return DemoCaptions.translation(of: text, in: speech) ?? "（演示翻译）"
        }
    }
#endif

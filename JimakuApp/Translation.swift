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
    func prepare(for languages: LanguagePair) async throws -> any PreparedTranslator
}

enum TranslationSetupError: LocalizedError {
    case languagePackMissing(LanguagePair)
    case languagePairNotSupported(LanguagePair)

    var errorDescription: String? {
        switch self {
        case .languagePackMissing(let languages):
            "\(languages.spoken.spokenName)翻译成\(languages.target.writtenName)的语言包还没下载。回到 Jimaku，在设置里点「下载」。"
        case .languagePairNotSupported(let languages):
            "系统的语言包不能把\(languages.spoken.spokenName)翻译成\(languages.target.writtenName)。"
        }
    }
}

/// Translation with the system's Translation framework. Nothing leaves the device.
///
/// The availability check, the session, and the download request in the
/// settings all leave the framework's strategy at its default, so they agree
/// with each other. Which strategy that is depends on the SDK the app is built
/// with and on the device; see
/// `docs/pitfalls/the-translation-framework-answers-by-a-default-strategy-that-changed-with-the-sdk.md`.
@MainActor
final class LanguagePackSource: TranslatorSource {
    func prepare(for languages: LanguagePair) async throws -> any PreparedTranslator {
        let source = languages.spoken.translationLanguage
        let target = languages.target.translationLanguage
        switch await LanguageAvailability().status(from: source, to: target) {
        case .installed:
            return LanguagePackTranslator(session: TranslationSession(installedSource: source, target: target))
        case .supported:
            throw TranslationSetupError.languagePackMissing(languages)
        case .unsupported:
            throw TranslationSetupError.languagePairNotSupported(languages)
        @unknown default:
            throw TranslationSetupError.languagePairNotSupported(languages)
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
    /// the demo speech up in its prepared translation, which is in Simplified
    /// Chinese whatever the target. Simulator only.
    @MainActor
    final class ScriptedSource: TranslatorSource, PreparedTranslator {
        private var speech: [CaptionLines] = []

        func prepare(for languages: LanguagePair) async throws -> any PreparedTranslator {
            speech = DemoCaptions.speech(in: languages.spoken)
            return self
        }

        func translate(_ text: String) async throws -> String {
            try? await Task.sleep(for: .milliseconds(150))
            return DemoCaptions.translation(of: text, in: speech) ?? "（演示翻译）"
        }
    }
#endif

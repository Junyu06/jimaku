import Foundation
import FoundationModels
import JimakuCore
import Speech
import Translation

/// Asks the system what it can do with the app's languages.
@MainActor
protocol LanguageSupportSource: AnyObject {
    func support() async -> LanguageSupport
}

extension CaptionLanguage {
    /// The language as the Translation framework takes it.
    var translationLanguage: Locale.Language { Locale.Language(identifier: identifier) }

    /// What to call the language where it is the one being spoken: the language
    /// without its script, since speech has none.
    var spokenName: String {
        Locale.current.localizedString(forLanguageCode: family) ?? englishName
    }

    /// What to call the language where captions are translated into it.
    var writtenName: String {
        Locale.current.localizedString(forIdentifier: identifier) ?? englishName
    }
}

#if !targetEnvironment(simulator)
    /// What the system's speech recognizer, translation language packs, and
    /// language model report on this device.
    @MainActor
    final class SystemLanguageSupport: LanguageSupportSource {
        func support() async -> LanguageSupport {
            var support = LanguageSupport()

            if SpeechTranscriber.isAvailable {
                for language in CaptionLanguage.all {
                    guard let identifier = language.recognizerLocale,
                        await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: identifier)) != nil
                    else { continue }
                    support.recognizable.insert(language)
                }
            }

            // A language the recognizer does not know is never offered, so its
            // language packs are not asked about.
            let availability = LanguageAvailability()
            for spoken in CaptionLanguage.all where support.recognizable.contains(spoken) {
                for target in CaptionLanguage.all {
                    let pair = LanguagePair(spoken: spoken, target: target)
                    guard pair.isTranslatable else { continue }
                    let status = await availability.status(
                        from: spoken.translationLanguage, to: target.translationLanguage)
                    support.packs[pair] =
                        switch status {
                        case .installed: .installed
                        case .supported: .downloadable
                        case .unsupported: .unsupported
                        @unknown default: .unsupported
                        }
                }
            }

            // A device that can never run the model is not offered it. One where
            // it is switched off or still downloading is: starting says what to do.
            let model = SystemLanguageModel.default
            if case .unavailable(.deviceNotEligible) = model.availability {
                return support
            }
            support.modelLanguages = Set(
                CaptionLanguage.all.filter { model.supportsLocale(Locale(identifier: $0.identifier)) })
            return support
        }
    }
#else
    /// The simulator has no speech recognition and no language packs to ask
    /// about, and its captions are scripted. Every language is reported as ready,
    /// so the settings can be tried. Simulator only.
    @MainActor
    final class ScriptedLanguageSupport: LanguageSupportSource {
        func support() async -> LanguageSupport {
            let spoken = CaptionLanguage.all.filter(\.canBeSpoken)
            var support = LanguageSupport(recognizable: Set(spoken), modelLanguages: Set(CaptionLanguage.all))
            for language in spoken {
                for target in CaptionLanguage.all {
                    let pair = LanguagePair(spoken: language, target: target)
                    if pair.isTranslatable { support.packs[pair] = .installed }
                }
            }
            return support
        }
    }
#endif

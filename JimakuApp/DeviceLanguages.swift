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

extension LanguageSupport {
    /// Fills in what the on-device language model reports. A device that can
    /// never run it is marked so; one where it is switched off or still being
    /// downloaded is not, and starting a session there says what to do.
    @MainActor
    fileprivate mutating func takeModel() {
        let model = SystemLanguageModel.default
        if case .unavailable(.deviceNotEligible) = model.availability {
            deviceRunsModel = false
            return
        }
        modelLanguages = Set(CaptionLanguage.all.filter { model.supportsLocale(Locale(identifier: $0.identifier)) })
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
                    // An answer this build does not know is left out: the
                    // pair then counts as not reported, not as without a pack.
                    let pack: LanguagePackStatus? =
                        switch status {
                        case .installed: .installed
                        case .supported: .downloadable
                        case .unsupported: .unsupported
                        @unknown default: nil
                        }
                    support.packs[pair] = pack
                }
            }

            support.takeModel()
            return support
        }
    }
#else
    /// The simulator has no speech recognition and no language packs to ask
    /// about, and its captions are scripted. Every language is reported as
    /// recognized and every pack as installed, so the settings can be tried.
    /// The language model is the host Mac's, and is asked as on a device.
    /// Simulator only.
    @MainActor
    final class ScriptedLanguageSupport: LanguageSupportSource {
        func support() async -> LanguageSupport {
            let spoken = CaptionLanguage.all.filter(\.canBeSpoken)
            var support = LanguageSupport(recognizable: Set(spoken))
            support.takeModel()
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

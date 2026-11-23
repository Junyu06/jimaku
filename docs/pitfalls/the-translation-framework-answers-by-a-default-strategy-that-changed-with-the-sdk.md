# The Translation framework answers by a default strategy that changed with the SDK

From iOS and macOS 26.4 the Translation framework has two strategies, `TranslationSession.Strategy.lowLatency` and `.highFidelity`. `LanguageAvailability()`, `TranslationSession(installedSource:target:)`, and `TranslationSession.Configuration(source:target:)` take one when asked and otherwise use a default. This app asks for none.

Measured on one Mac (macOS 27.2) on 2026-11-23:

- Asked about the same pairs within minutes, test programs built against the 27.0 SDK were told `.installed` for every pair of the app's languages except Chinese into Chinese, and translated Korean and Spanish into Simplified Chinese. The same source built with `swift build`, whose binary recorded SDK 26.0, was told `.installed` only for English, Japanese, and Simplified Chinese among themselves and `.supported` for the rest, and its translation of Korean failed with `notInstalled`.
- A program built against the 27.0 SDK that named the strategy got the first set of answers with `.highFidelity` and with no strategy named, and the second set with `.lowLatency`. A session made without naming one reported `.highFidelity` as its strategy.
- Translating eight Japanese clauses into Simplified Chinese, one at a time on a session already used once, took a median of 0.02 seconds with `.lowLatency` and 0.22 with `.highFidelity`, twice each.

So on that Mac, built with that SDK, the default is the high-fidelity strategy. There it reported the pairs asked about as installed whether or not their language packs were downloaded, and it was about ten times slower a sentence. What it reports on another device, or on one without Apple Intelligence, was not measured. Copying a program elsewhere, signing it again, and the minimum system version it was compiled for did not change which answers it got.

What this means here:

- The engine the settings call 语言包 (language packs) is whatever the default strategy is for the build and the device. Where the default reports a pair as installed, as it did for every pair asked about on that Mac, the row that offers a download does not appear for it, and the time a translation takes is that strategy's. Which strategy a build of this app gets on an iPad or iPhone has not been seen.
- The availability check, the session, and the download request must all leave the strategy unnamed or all name the same one. If one of them differed, the settings would say a pack is there that the session then cannot find, or the other way round.
- Do not write down which language packs a device has from a test program. The app asks each time it opens or comes to the front and offers what it is told.
- Times measured on a Mac are not the device's; see `a-mac-answers-a-request-to-finalize-much-later-than-an-ipad.md`.

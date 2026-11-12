---
area: translation
status: not-run
---

# Captions are translated into Chinese

- Input: on an iPhone and an iPad with the English, Japanese, and Simplified Chinese translation languages downloaded: start a session, then watch an English video and a Japanese video in a video app and one video in a social feed app, two to three minutes each.
- Expected result: the floating window shows the original line on top and a Simplified Chinese line below. The Chinese for a piece of speech appears a second or two after it was said, stays while the next is spoken, and can be followed by a reader. Without the language pack downloaded, the app says which languages to download and keeps showing original-language captions.
- Property: kept speech is translated on the device with the system language packs while the app is in the background.

## Evidence

- 2026-11-12, physical iPad, earlier version: the floating window showed a Simplified Chinese line under the Japanese line. It lagged behind continuous speech; see translation-003. English, the social feed app, and the missing-language-pack message were not reported. From the owner's screenshots.
- Physical iPad, current version: not run.
- Physical iPhone: not run.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, with scripted text standing in for both the recognizer and the translator (the simulator has neither): the original row grew, and the Chinese row gained each piece after it was kept and held it during the next one. This exercises the transcript, the backlog, and the window, not translation.
- 2026-11-12: the app including `LanguagePackTranslator` compiles for `generic/platform=iOS`. The current version has not run on a device.

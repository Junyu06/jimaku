---
area: translation
status: not-run
---

# Captions are translated into Chinese

- Input: on an iPhone and an iPad with the English, Japanese, and Simplified Chinese translation languages downloaded, 目标语言 (target language) set to 简体中文 and 翻译引擎 (translation engine), where it is shown, to 语言包 (language packs): with 源语言 (source language) on 英语, start a session and watch an English video in a video app and one video in a social feed app, two to three minutes each. Stop, choose 日语, start again, and watch a Japanese video.
- Expected result: the floating window shows the original line on top and a Simplified Chinese line below. The Chinese for a sentence appears soon after the sentence ends, stays while the next is spoken, and can be followed by a reader. What happens without the language pack is in language-006.
- Property: kept speech is translated on the device by the Translation framework while the app is in the background. These steps do not show which of the framework's strategies did the translating; see `docs/pitfalls/the-translation-framework-answers-by-a-default-strategy-that-changed-with-the-sdk.md`.

## Evidence

- 2026-11-12, physical iPad, earlier version: the floating window showed a Simplified Chinese line under the Japanese line. It lagged behind continuous speech; see translation-003. English, the social feed app, and the missing-language-pack message were not reported. From the owner's screenshots.
- Physical iPad, current version: not run.
- Physical iPhone: not run.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, with scripted text standing in for both the recognizer and the translator (the simulator has neither): the original row grew, and the Chinese row gained each piece after it was kept and held it during the next one. This exercises the transcript, the backlog, and the window, not translation.
- 2026-11-12: the app including `LanguagePackTranslator` compiles for `generic/platform=iOS`. The current version has not run on a device.

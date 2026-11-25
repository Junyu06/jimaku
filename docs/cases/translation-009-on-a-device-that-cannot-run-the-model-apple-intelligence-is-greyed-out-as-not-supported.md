---
area: translation
status: not-run
---

# On a device that cannot run the model Apple Intelligence is greyed out as not supported

- Fixture: the app with its interface in Chinese, on a device that is not eligible for Apple Intelligence, that recognizes English, and for which the system reports the language pack for English into Simplified Chinese as installed or as available to download; 源语言 (source language) 英语 and 目标语言 (target language) 简体中文.
- Input: wait a few seconds after the app opens, so that the system has answered, then open 翻译引擎 (translation engine) in the settings and tap the line for Apple Intelligence.
- Expected result: the list shows 语言包 with the check mark and a grey line "Apple Intelligence（这台设备不支持）", and after the tap 翻译引擎 still reads 语言包.
- Property: where the model can never run, the engine is still listed and says that the device does not support it.

## Evidence

- No such device was at hand: not run.
- The rule that gives this reason is covered by tests of JimakuCore (`LanguageSupport`, `LanguageSettings`).

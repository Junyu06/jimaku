---
area: translation
status: not-run
---

# On a device that cannot run the model Apple Intelligence is greyed out as not supported

- Fixture: the app with its interface in Chinese, on a device that is not eligible for Apple Intelligence.
- Input: open 翻译引擎 (translation engine) in the settings, with 说话的语言 (spoken language) 英语 and 翻译成 (translate into) 简体中文.
- Expected result: the list shows 语言包 with the check mark and a grey line "Apple Intelligence（这台设备不支持）", and tapping the grey line changes nothing.
- Property: where the model can never run, the engine is still listed and says that the device does not support it.

## Evidence

- No such device was at hand: not run.
- The rule that gives this reason is covered by tests of JimakuCore (`LanguageSupport`, `LanguageSettings`).

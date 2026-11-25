---
area: translation
status: simulated
---

# Given as text on a Mac a refusal the model throws comes out of the app's translator as the app's own message

- Fixture: the three sentences of translation-006 and the same command-line program, with the app's translator class given `SystemLanguageModel.default`, whose guardrails refuse them, in place of the model the app prepares.
- Input: hand each sentence once, as text, to that translator.
- Expected result: each call throws an error whose description is "Apple Intelligence 没有翻译这一句。", not the system's "The model's safety guardrails were triggered."
- Property: a refusal the model throws leaves the app's translator as an error with the app's own description.

## Evidence

- 2026-11-23, one Mac (macOS 27.2): each of the three calls threw the app's error with that description. The error the system threw underneath was a `LanguageModelError`; the earlier error type, which a system before 27 would throw, was not produced. Not the app and not a device: that the session shows this description, after "翻译出错：", was not run.
- Physical iPad: not run.
- Physical iPhone: not run.

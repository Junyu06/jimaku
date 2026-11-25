---
area: language
status: not-run
---

# Speech in Chinese is captioned in English

- Input: on a device, choose 说话的语言 (spoken language) 中文 and 翻译成 (translate into) 英语, set 显示 (display) to 原文和译文 (original and translation), start a session, and play a video with Mandarin speech in a video app for two to three minutes.
- Expected result: the floating window shows the Chinese line on top, without a space before its commas, and an English line below it that a reader can follow.
- Property: a pair of languages other than the first two goes through the same recognition, cutting, and translation as English and Japanese into Chinese.

## Evidence

- Physical iPad, 2026-11-23, reported by the owner with one screenshot: a session with 中文 into 英语, the Apple Intelligence engine, and 只显示译文 (translation only). The owner reported the settings and the session as working. In the screenshot the entries of the session's captions that are visible have an English line under the Chinese one, and the Chinese visible in it has no space before its commas. The window in it shows original Chinese, and the app shows the message of the model's guardrails; see `docs/pitfalls/the-on-device-model-refuses-to-translate-sentences-its-default-guardrails-object-to.md`. The window with both rows, as this case asks, was not shown, so the case is not marked as passed.
- Physical iPhone: not run.
- What the recognizer and the Translation framework do with Mandarin was tried on a Mac, outside the app; see language-007.

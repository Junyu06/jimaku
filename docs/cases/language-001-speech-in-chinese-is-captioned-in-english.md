---
area: language
status: not-run
---

# Speech in Chinese is captioned in English

- Input: on a device, choose 说话的语言 (spoken language) 中文 and 翻译成 (translate into) 英语, start a session, and play a video with Mandarin speech in a video app for two to three minutes.
- Expected result: the floating window shows the Chinese line on top, without a space before its commas, and an English line below it that a reader can follow.
- Property: a pair of languages other than the first two goes through the same recognition, cutting, and translation as English and Japanese into Chinese.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- What the recognizer and the Translation framework do with Mandarin was tried on a Mac, outside the app; see language-007.

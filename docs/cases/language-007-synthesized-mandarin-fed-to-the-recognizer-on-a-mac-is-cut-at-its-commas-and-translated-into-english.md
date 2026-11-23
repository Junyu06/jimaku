---
area: language
status: simulated
---

# Synthesized Mandarin fed to the recognizer on a Mac is cut at its commas and translated into English

- Input: on a Mac, an 18-second audio file of one long Mandarin sentence with six commas, written for this test and spoken by the system voice. A command-line program feeds the file to `SpeechTranscriber` for `zh-CN` with progressive transcription, passes each result through the app's rule for spaces before marks and then to JimakuCore's `Transcript` with the rules for Chinese, and gives each kept piece to a Translation framework session for Simplified Chinese into English, made the way the app makes it, with no strategy named.
- Expected result: the pieces together are the whole sentence, each piece ends at a comma or at the end of the sentence, none has a space before a comma, and each gets an English sentence.
- Property: the recognizer's Mandarin, as it actually comes, works with the cutting rules borrowed from Japanese, and the pieces are ones the Translation framework can translate.

## Evidence

- 2026-11-23, Mac (macOS 27.2): the recognizer's results had a space before every full-width comma. The transcript kept four pieces of 16 to 22 characters, each ending at a comma or at the end, with no space before a comma, and the Translation framework turned each into an English sentence (the first piece, about going to a supermarket for fruit and milk, came out as "I went to the supermarket this morning and bought some fruits and milk."). This run used the rule as it was first written, applied to every language; for Chinese text with plain spaces the present rule does the same. The program was built against the 27.0 SDK and named no translation strategy, so the translation was by the framework's default, which on that Mac was the high-fidelity strategy and not the downloaded language packs; see `docs/pitfalls/the-translation-framework-answers-by-a-default-strategy-that-changed-with-the-sdk.md`.
- A file is fed faster than speech and without the app's pause detection, the broadcast, or the floating window. This shows what is recognized and where the marks cut it, not when captions appear and not that a session works; language-001 is the case for that.

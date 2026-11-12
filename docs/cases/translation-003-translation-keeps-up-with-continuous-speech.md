---
area: translation
status: simulated
---

# Translation keeps up with continuous speech

- Input: on a device, start a session and watch a fast-cut video in which the speaker talks without pauses for ten seconds or more.
- Expected result: the Chinese row keeps moving with the speech: each sentence is translated when it ends, and the unfinished end shows a provisional translation that grows. The Chinese row is never more than a sentence behind the original row.
- Property: translation does not wait for the recognizer to finalize a long stretch of speech.

## Evidence

- 2026-11-12, physical iPad, earlier version that waited for final results: with a Japanese short video, the original row filled with several sentences while the Chinese row still showed an earlier one. Reported by the owner with two screenshots. This is the failure this case exists for.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, scripted speech delivered as one growing stretch: each sentence was translated when it ended, the unfinished end showed a provisional translation, and both rows ran on. Simulator only.
- Physical iPad, this version: not run.
- Physical iPhone: not run.

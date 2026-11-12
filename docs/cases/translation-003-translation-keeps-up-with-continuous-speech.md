---
area: translation
status: simulated
---

# Translation keeps up with continuous speech

- Input: on a device, start a session and watch a fast-cut video in which the speaker talks without pauses for ten seconds or more.
- Expected result: the Chinese row keeps up with the speech sentence by sentence. A sentence is translated soon after it ends; one that runs on is cut after about four seconds, or up to about eight when it offers no place to cut. Until then the row shows a dim "…". The Chinese row is never more than a few seconds behind the speaker, and each translation stays long enough to read.
- Property: translation does not wait for the recognizer to finalize a long stretch of speech.

## Evidence

- 2026-11-12, physical iPad, earlier version that waited for final results: with a Japanese short video, the original row filled with several sentences while the Chinese row still showed an earlier one. Reported by the owner with two screenshots. This is the failure this case exists for.
- 2026-11-12, physical iPad, second version, which rebuilt and retranslated its sentences from every guess: the Chinese row kept up but was rewritten as the speaker went on. Reported by the owner as hard to read; see window-002.
- 2026-11-12, what the system recognizer reported on a Mac for about twenty seconds of continuous synthetic Japanese, replayed in a unit test: nine pieces were kept before the recognizer finalized anything, the first four seconds in and the others one to three seconds apart. The recording has no times for when each piece was said, so the delay behind the speaker was not measured. This exercises the transcript, not the device.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, third version, scripted speech delivered as one growing stretch: pieces were translated while the stretch went on, and the unfinished end showed a dimmer provisional translation. Simulator only.
- 2026-11-12, physical iPad, third version, which cut a piece about every three seconds and showed a provisional translation: the owner reported that translations changed or were gone before they could be read. See window-002.
- 2026-11-12, the same recording replayed with this version's rules: seven pieces, each a sentence or a clause ending in a comma, all kept before the final result.
- Physical iPad, this version: not run.
- Physical iPhone: not run.

---
area: translation
status: passed
---

# A caption appears when the speaker stops

- Input: on a device, start a session and watch a video of people talking in short turns, a few words to a sentence each, with a third of a second or more of quiet between turns and no music or noise under the speech.
- Expected result: each turn becomes one caption. Its Chinese appears on a line of its own within about a second after the speaker stops, before the next speaker has finished. Short turns by different speakers are not run together into one caption, and a sentence is not cut in the middle of a phrase.
- Property: a caption ends where the speaker pauses, not where the recognizer happens to finalize and not at a length limit.

## Evidence

- 2026-11-12, physical iPad, the version that told a pause from the recognizer's guesses, on a Japanese video of quick conversation: the owner reported that the result was unusable, with captions late and cut by length. Two screenshots show the Chinese row a sentence or more behind the original row. This is the failure this case exists for.
- 2026-11-12, on a Mac, that version's rules fed by the app's recognizer class with a 145-second recording of quick Japanese conversation, played at its own speed: the first four turns, spoken over eight seconds, came out as one caption 10.7 seconds in. 39 captions in all, several cut inside a phrase.
- 2026-11-12, on a Mac, this version on the same recording, with the pause detector, the recognizer asked to finalize at each pause, the transcript, and language-pack translation: the first caption was translated 3.2 seconds in, as its speaker stopped. 63 captions: 61 kept within 0.1 seconds after a pause was noticed, and 2 while the speaker went on, one at a sentence ending in the recognizer's guess and one by the length limit. Each was translated within 0.1 seconds of being kept. Fed in two-second batches instead, the same recording gave one caption per pause as well. This is the app's own code on a Mac, with audio from a file instead of a screen broadcast.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, scripted English delivered a sentence at a time: each translation started on a new line; a translation that needed both lines was shown alone. Simulator only.
- 2026-11-12, physical iPad, the first build of this version, a Japanese video of quick conversation played in another app during a screen broadcast, logged by the app: 67 pauses were found in 154 seconds and none was acted on; the recognizer finalized 15 times, 2 to 26 seconds apart. The owner reported the first translation about ten seconds in, after the first exchange was over. Failed. The cause is in `docs/pitfalls/during-a-broadcast-the-speech-analyzers-volatile-range-stops-short-of-the-audio-handed-over.md`.
- 2026-11-12, physical iPad, this version with that fixed, the same kind of video for 46 seconds, logged by the app: 19 pauses found; 17 gave a final result 0.04 to 0.08 seconds after the pause was noticed and 2 gave none; 18 captions: 17 kept at those final results and 1 at a sentence ending in the recognizer's guess. The Chinese was ready 0.2 to 0.3 seconds after the pause, 0.6 for the first. The owner reported that a translation appears as soon as a speaker stops. Passed on iPad.
- Physical iPhone: not run.

---
area: window
status: simulated
---

# Caption text stays in place until its line rolls up

- Input: on a device, start a session and watch a video with continuous speech for a minute.
- Expected result: on each row, bright text never changes and never moves sideways. Each sentence starts on a new line. When a row is full, the oldest sentence leaves with all its lines and the others move up; a row does not begin with the end of a sentence whose beginning is gone, except to show the rest of one that is longer than the row. On the original row the speech in progress is dimmer and may change. The Chinese row has no text that changes: only finished translations, and a dim "…" at its end while more is waiting.
- Property: a reader can keep their place, because text that has been shown as settled is not rewritten or moved except by a whole line.

## Evidence

- 2026-11-12, physical iPad, version before this one: both rows slid by a character at a time and the Chinese row was rewritten as the speaker went on. Reported by the owner with three screenshots as hard to read. This is the failure this case exists for.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, scripted Japanese and English delivered the way the recognizer was seen to deliver continuous speech: in frames taken about half a second apart, bright text stayed where it was between rolls, rows rolled by one line, and the provisional translation stayed within one line's worth. Japanese was checked at medium and large text size, English at large. Simulator only.
- 2026-11-12, physical iPad, the version with fixed lines and a dimmer provisional translation, on a Japanese short video: the rows no longer slid. The owner reported that the dim Chinese was read like the rest and was then replaced by different bright text, and that pieces came too often to read. Three screenshots. That led to showing finished translations only; see `docs/decisions/2026-11-12-translate-a-sentence-only-when-it-has-ended.md`.
- 2026-11-12, iPad mini (A17 Pro) simulator, this version, scripted English at medium text size: in frames about three quarters of a second apart, the Chinese row showed bright text only, unchanged between rolls, with a dim "…" at its end while speech was waiting. Simulator only.
- 2026-11-12, iPad mini (A17 Pro) simulator, the version that starts each sentence on a new line, scripted English at medium text size: in frames about 1.2 seconds apart, each translation began a line, two short ones shared the row, and one that needed both lines stood alone. Simulator only.
- Physical iPad, this version: not run.
- Physical iPhone: not run.

---
area: window
status: simulated
---

# Caption text stays in place until its row rolls or turns a page

- Input: on a device, start a session and watch a video with continuous speech for a minute.
- Expected result: on each row, bright text never changes and never moves sideways. Each sentence starts on a new line. The Chinese row fills from the top; when the next translation does not fit in the lines left, the row is cleared and that translation starts a new page at the top, so nothing on the Chinese row moves while its page is up. A page does not begin with the end of a translation whose beginning is gone, except to show the rest of one that is longer than a whole page. The original row rolls: when it is full the oldest sentence leaves and the rest move up. On the original row the speech in progress is dimmer and may change. The Chinese row has no text that changes: only finished translations, and a dim "…" at its end while more is waiting.
- Property: a reader can keep their place, because text that has been shown as settled is not rewritten or moved except by a whole line.

## Evidence

- 2026-11-12, physical iPad, version before this one: both rows slid by a character at a time and the Chinese row was rewritten as the speaker went on. Reported by the owner with three screenshots as hard to read. This is the failure this case exists for.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, scripted Japanese and English delivered the way the recognizer was seen to deliver continuous speech: in frames taken about half a second apart, bright text stayed where it was between rolls, rows rolled by one line, and the provisional translation stayed within one line's worth. Japanese was checked at medium and large text size, English at large. Simulator only.
- 2026-11-12, physical iPad, the version with fixed lines and a dimmer provisional translation, on a Japanese short video: the rows no longer slid. The owner reported that the dim Chinese was read like the rest and was then replaced by different bright text, and that pieces came too often to read. Three screenshots. That led to showing finished translations only; see `docs/decisions/2026-11-12-translate-a-sentence-only-when-it-has-ended.md`.
- 2026-11-12, iPad mini (A17 Pro) simulator, this version, scripted English at medium text size: in frames about three quarters of a second apart, the Chinese row showed bright text only, unchanged between rolls, with a dim "…" at its end while speech was waiting. Simulator only.
- 2026-11-12, iPad mini (A17 Pro) simulator, the version that starts each sentence on a new line, scripted English at medium text size: in frames about 1.2 seconds apart, each translation began a line, two short ones shared the row, and one that needed both lines stood alone. Simulator only.
- 2026-11-12, iPad mini (A17 Pro) simulator, the version in which the Chinese row turns pages, scripted Japanese at the small text size with five lines: in frames about three seconds apart, the Chinese row filled from the top, its lines stayed where they were while it filled, and a full page was replaced whole by the next translation. Simulator only.
- Physical iPad, this version: not run.
- Physical iPhone: not run.

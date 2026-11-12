---
area: window
status: simulated
---

# Caption text stays in place until its line rolls up

- Input: on a device, start a session and watch a video with continuous speech for a minute.
- Expected result: on each row, bright text never changes and never moves sideways. New text appears at its end. When a row is full, its lines move up by one and the oldest leaves. The speech in progress and its provisional translation are dimmer than the rest and may change; the provisional translation takes at most about one line.
- Property: a reader can keep their place, because text that has been shown as settled is not rewritten or moved except by a whole line.

## Evidence

- 2026-11-12, physical iPad, version before this one: both rows slid by a character at a time and the Chinese row was rewritten as the speaker went on. Reported by the owner with three screenshots as hard to read. This is the failure this case exists for.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, scripted Japanese and English delivered the way the recognizer was seen to deliver continuous speech: in frames taken about half a second apart, bright text stayed where it was between rolls, rows rolled by one line, and the provisional translation stayed within one line's worth. Japanese was checked at medium and large text size, English at large. Simulator only.
- Physical iPad, this version: not run.
- Physical iPhone: not run.

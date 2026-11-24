---
area: audio
status: simulated
---

# With captions already shown and no broadcast, the caption window says the recording is off

- Input: in an iPad simulator, which has Picture in Picture, launch the app with the argument `-simulatedRecording off`, tap 开始 (Start), and wait six seconds. The simulator's recognizer is scripted and produces captions without any audio.
- Expected result: the session's log on the page lists captions with their translations, and the caption window shows none of them: it reads 录屏未打开.
- Property: with no broadcast running, the window says so even when it has captions to show.

## Evidence

- 2026-11-24, iPad mini (A17 Pro) simulator, iOS 27.0: the window read 录屏未打开 while the log listed two captions. In the same state the build before this change showed the captions in the window.
- Physical device: not run.

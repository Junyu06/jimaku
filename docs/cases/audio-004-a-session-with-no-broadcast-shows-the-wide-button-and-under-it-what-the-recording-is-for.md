---
area: audio
status: simulated
---

# A session with no broadcast shows the wide button and under it what the recording is for

- Input: in an iPad simulator, which has Picture in Picture, launch the app with the arguments `-simulatedRecording off -recordingExplanationRead YES`, which leave the stand-in for the broadcast off and the explanation of the recording read, and tap 开始 (Start).
- Expected result: once the caption window is up, the page shows under the preview a filled button as wide as the page reading 打开录屏, under it the small line `用来听视频的声音` (for hearing the video's sound) with a question mark in a circle, and under that 停止 (Stop) as a grey button. No round glyph and no lines between these rows.
- Property: while a session's window is up and nothing is being broadcast, the page offers the recording as its one filled button, and says in a few words what the recording is for.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0, interface in Simplified Chinese: the page showed exactly that. With a build that logged it, taps 16 points from either end of the wide button fired the system control's action and did not bring up the explanation. A simulation: the simulator has no screen broadcast, and its recognizer is scripted, so captions went on appearing in the window with the recording off.
- 2026-11-23, same simulator: the page as it was then, with the label `只用声音，不保存画面` in place of that line.
- Physical device: not run.

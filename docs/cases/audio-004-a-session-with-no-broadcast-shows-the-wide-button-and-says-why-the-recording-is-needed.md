---
area: audio
status: simulated
---

# A session with no broadcast shows the wide button and says why the recording is needed

- Input: in an iPad simulator, which has Picture in Picture, launch the app with the argument `-simulatedRecording off`, which leaves the stand-in for the broadcast off, and tap 开始 (Start).
- Expected result: once the caption window is up, the page shows under the preview a filled button as wide as the page reading 打开录屏, under it the sentence `Jimaku 要靠录屏才能听到视频里的声音，画面不会保存。系统会让你点一次「开始直播」。`, and under that 停止 (Stop) as a grey button. No round glyph and no lines between these rows.
- Property: while a session's window is up and nothing is being broadcast, the page offers the recording as its one filled button and says why.

## Evidence

- 2026-11-23, iPad mini (A17 Pro) simulator, iOS 27.0, interface in Simplified Chinese: the page showed exactly that. A simulation: the simulator has no screen broadcast, and its recognizer is scripted, so captions went on appearing in the window with the recording off.
- Physical device: not run.

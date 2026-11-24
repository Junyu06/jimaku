---
area: audio
status: simulated
---

# A broadcast that carries no sound shows a label saying the recording is on and there is no sound

- Input: in an iPad simulator, which has Picture in Picture, launch the app with the argument `-simulatedRecording silent`, which stands in for a broadcast that runs and hands over no audio, wait two seconds, and tap 开始 (Start).
- Expected result: once the caption window is up, the page shows no 打开录屏 button. Under the preview it reads `录屏已打开，暂无声音` (the recording is on, no sound for now), and 停止 (Stop) is the filled button.
- Property: once a broadcast runs, the page stops offering the recording and says what state it is in.

## Evidence

- 2026-11-23, iPad mini (A17 Pro) simulator, iOS 27.0, interface in Simplified Chinese: the page showed exactly that. A simulation: no broadcast ran.
- Physical device: not run.

---
area: audio
status: simulated
---

# The question mark under the wide button brings up the page that says why the recording is needed

- Input: in an iPad simulator, launch the app with the arguments `-simulatedRecording off -recordingExplanationRead YES`, tap 开始 (Start), and once the wide button shows, tap the line with the question mark under it. Then tap 好 (OK) on the page that comes up.
- Expected result: a sheet comes up titled 为什么要打开录屏 with three rows: what the recording is for, that no picture is kept, and that the system asks for it at each start. Its button reads 好; after the tap on it the page is gone and the session goes on.
- Property: where the page asks for the recording, the reason is one tap away.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0, interface in Simplified Chinese: the sheet came up with that title, those rows, and 好, over a session that kept running. The tap on 好 was not part of that run; the same button, reading 继续, closed the page in `audio-009`.
- Physical device: not run.

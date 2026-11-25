---
area: audio
status: simulated
---

# The question mark under the wide button brings up the page that says why the recording is needed

- Input: in an iPad simulator, launch the app with the arguments `-simulatedRecording off -recordingExplanationRead YES`, tap 开始 (Start), and once the wide button shows, tap the line with the question mark under it. Then tap 确认 (Confirm) on the page that comes up.
- Expected result: a sheet comes up titled 为什么要打开录屏 with three rows: what the recording is for, that no picture is kept, and that the system asks for it at each start. Its button reads 确认; after the tap on it the page is gone and the session goes on.
- Property: where the page asks for the recording, the reason is one tap away.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0, interface in Simplified Chinese: the sheet came up with that title and those rows over a session that kept running. Its button then read 好 (OK); the owner had it changed to 确认 the same day, and this fixture has not been run again since. The tap on the button was not part of that run; the same button closed the page in `audio-009` and `audio-011`.
- Physical device: not run.

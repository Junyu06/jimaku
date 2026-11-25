---
area: audio
status: simulated
---

# The help row brings up the page that says why the recording is needed, with no session running

- Input: in an iPad simulator, launch the app with the argument `-recordingExplanationRead YES` and, without starting a session, tap the row 为什么要打开录屏 in the section 帮助 under the settings. Then tap 确认 (Confirm).
- Expected result: the sheet titled 为什么要打开录屏 comes up with its three rows and the button 确认; after the tap on it the sheet is gone, and no session has started.
- Property: the reason for the recording can be read again at any time, not only at the first start or while the recording is off.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0, interface in Simplified Chinese: the row was under the settings with no session running, and the tap brought up that sheet with 确认; after the tap on 确认 the sheet was gone and the main button still read 开始.
- Physical device: not run.

---
area: audio
status: simulated
---

# The first tap on Start shows why the recording is needed, and the session starts when that page is closed with its button

- Input: in an iPad simulator, launch the app with the arguments `-simulatedRecording off -recordingExplanationRead NO`, which stand for an app whose explanation of the recording has never been closed with its button. Tap 开始 (Start). Then tap 继续 (Continue) on the page that comes up.
- Expected result: after the first tap a sheet comes up titled 为什么要打开录屏, with three rows and the button 继续, and no caption window appears. After 继续 the sheet goes, the caption window comes up, and the app presses the system's broadcast control once.
- Property: a first session is not started, and the system's sheet not asked for, before the user has been told why the recording is needed.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0: the sheet came up after 开始 with no caption window; after 继续 the caption window came up and, in a build that logged it, the app sent the system control's button the event once. A simulation: the simulator has no screen broadcast and shows no system sheet.
- Tests of JimakuCore (`RecordingExplanation`) cover only the rule: the page is due before a first start and not once it has been read. In the same simulator, launched with `-recordingExplanationRead YES`, 开始 brought up the caption window with no page before it.
- Physical device: not run.

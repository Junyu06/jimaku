---
area: interface
status: simulated
---

# Launched in English, the start page, the recording page, and the caption window show no Chinese

- Input: in an iPad simulator, launch the app with the arguments `-AppleLanguages "(en)" -simulatedRecording off -recordingExplanationRead NO`. Look at the start page, tap Start, look at the page that comes up, tap Continue, and look at the start page and the caption window.
- Expected result: every label, title, and button on the start page, on the page that says why the recording is needed, and on the start page with a session running is in English, the names of the languages in the settings included; the preview shows an English caption; the caption window reads `Screen recording is off`. No Chinese text is on the screen.
- Property: the interface has an English version that the system's choice of language brings up.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0: all of that was in English. Launched with `-AppleLanguages "(zh-Hans)"`, the start page was in Chinese as before. A simulation: the simulator stands in for the system's choice with a launch argument. Not looked at: the notices that need a failure to show, and the rows for a missing language pack or an engine that cannot be chosen.
- Physical device: not run.

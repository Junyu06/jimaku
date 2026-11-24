---
area: audio
status: not-run
---

# Tapping Start brings up the system's broadcast sheet without another tap

- Input: on a device with no screen broadcast running, open the app and tap 开始 (Start) once. Touch nothing else.
- Expected result: the caption window appears, and then the system's screen-broadcast sheet comes up, once, with Jimaku as its extension.
- Property: the app can press the system's broadcast control in code once the caption window is up.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- The simulator has no screen broadcast and shows no sheet. In an iPad mini (A17 Pro) simulator on iOS 27.0, 2026-11-23, with a build that logged it, the app found the control's button and sent it the event once after 开始. That shows the app has a button to press there, not that a sheet follows.

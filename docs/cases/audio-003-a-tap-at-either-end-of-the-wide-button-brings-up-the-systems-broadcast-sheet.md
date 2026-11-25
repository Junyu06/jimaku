---
area: audio
status: not-run
---

# A tap at either end of the wide button brings up the system's broadcast sheet

- Input: on a device, with a session running, no broadcast running, and no sheet on screen (close the system's sheet if it is up), tap the button 打开录屏 (open the recording) near its left end. Close the sheet without starting a broadcast, and tap the button near its right end.
- Expected result: each of the two taps brings up the system's screen-broadcast sheet.
- Property: the system's control, stretched over the button the page draws and left all but invisible, takes a tap at both ends of that button.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- The simulator has no screen broadcast and shows no sheet. In an iPad mini (A17 Pro) simulator on iOS 27.0, 2026-11-23, with a build that logged it, taps 15 points from either end of the button reached the control's button and fired its action. That is not a sheet, and not a device.

---
area: audio
status: not-run
---

# With VoiceOver the wide button is read as its name and activating it brings up the sheet

- Input: on a device with VoiceOver on, with a session running, no broadcast running, and no sheet on screen, move the VoiceOver cursor to the button 打开录屏 (open the recording) and double-tap.
- Expected result: VoiceOver reads 打开录屏 once for that button, as a button, and the double-tap brings up the system's screen-broadcast sheet.
- Property: the system's control under the page's button is what assistive technology finds and activates, under the name the page shows.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- Simulator: not run. The simulator has no VoiceOver.

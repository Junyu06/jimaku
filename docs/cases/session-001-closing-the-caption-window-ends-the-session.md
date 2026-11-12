---
area: session
status: not-run
---

# Closing the caption window ends the session

- Input: on a device, during a session with a screen broadcast running, close the floating window with its close button.
- Expected result: captions stop, the button in the app reads 开始 (Start) again, and the screen broadcast ends, shown by a system alert that says 字幕已停止。 If the system does not end the broadcast, the user can end it from the system recording indicator.
- Property: the user can stop everything from the window itself.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0: tapping 停止 (Stop) in the app removed the window and reset the button. The window's own close button and ending a real broadcast were not exercised; the simulator has no screen broadcast.

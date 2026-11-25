---
area: audio
status: not-run
---

# Stopping the broadcast in the middle of a session makes the caption window say the recording is off

- Input: on a device, run a session over a video until captions are in the caption window, then stop the screen broadcast from the system's controls without closing the window. Leave the video playing.
- Expected result: within some five seconds the caption window reads 录屏未打开 in place of its captions.
- Property: the app notices a broadcast that ended while its session runs, and the window says so where the user is looking.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- The simulator has no screen broadcast to stop.

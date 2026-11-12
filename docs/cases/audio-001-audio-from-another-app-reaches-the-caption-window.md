---
area: audio
status: not-run
---

# Audio from another app reaches the caption window

- Input: on a device, tap 开始 (Start), confirm the system screen broadcast for Jimaku, switch to a video app, play a video, pause it, play it again.
- Expected result: the floating window shows a level meter that moves with the video's sound, falls to empty while the video is paused, and moves again when it resumes. Returning to the app and tapping 停止 (Stop) also ends the screen broadcast.
- Property: the broadcast extension receives other apps' audio and hands it to the app through the shared ring while the app is in the background.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, with a synthetic writer standing in for the extension (the simulator has no screen broadcast): the meter in the floating window alternated between full and empty about once a second while Safari was in front. This exercises the ring, the reader, and the meter, not the extension.

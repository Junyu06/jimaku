---
area: audio
status: not-run
---

# Audio from another app reaches the caption window

- Input: on a device, tap 开始 (Start), confirm the system screen broadcast for Jimaku, switch to a video app, play a video, pause it, play it again.
- Expected result: before anything is said, the floating window reads 正在听… (listening) while the video plays and 暂时没有声音 (no sound for now) while it is paused; once people speak, captions appear and go on appearing after a pause and resume. Returning to the app and tapping 停止 (Stop) also ends the screen broadcast.
- Property: the broadcast extension receives other apps' audio and hands it to the app through the shared ring while the app is in the background.

## Evidence

- 2026-11-12, physical iPad, earlier version: during a session over a short-video app the level meter was drawn and speech was recognized, so audio reached the app. Pausing and resuming, and ending the broadcast with 停止, were not reported. From the owner's screenshots.
- 2026-11-12, physical iPad, several later versions: captions appeared in every session over a short-video app, and two sessions were logged by the app with the audio it received. The notices before speech, pausing and resuming, and ending the broadcast with 停止 were not reported.
- The level meter these runs showed was taken out afterwards; see `docs/decisions/2026-11-12-take-the-audio-meter-out-of-the-caption-window.md`.
- Physical iPad, current version: not run.
- Physical iPhone: not run.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, with a synthetic writer standing in for the extension (the simulator has no screen broadcast): the meter in the floating window alternated between full and empty about once a second while Safari was in front. This exercises the ring, the reader, and the meter, not the extension.

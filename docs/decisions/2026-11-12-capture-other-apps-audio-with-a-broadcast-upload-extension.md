date: 2026-11-12
status: accepted
supersedes: none

# Capture other apps' audio with a broadcast upload extension and recognize it in the main app

A ReplayKit broadcast upload extension receives the audio that other apps play and hands it to the main app, which runs speech recognition and translation.

Why: a broadcast upload extension is the system-provided way for a third-party app to receive audio from other apps. The extension process has a small memory budget, so it only forwards audio; the heavier work runs in the main app.

Cost accepted: the system asks the user to confirm the broadcast every time a session starts. DRM-protected playback and phone or FaceTime call audio are not delivered.

Status of evidence: not yet verified on a device. Whether the hand-off and background recognition stay alive through a long session is an open question.

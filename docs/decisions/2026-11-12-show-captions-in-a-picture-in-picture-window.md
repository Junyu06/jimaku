date: 2026-11-12
status: accepted
supersedes: none

# Show captions in a Picture in Picture window

Captions are drawn into a Picture in Picture window so they float above whatever app is being watched, on both iPhone and iPad.

Why: iOS does not let an app draw over other apps. Picture in Picture is the system mechanism that stays on screen across apps, and it works the same way on iPhone and iPad, so one implementation covers both.

Cost accepted: the system allows one Picture in Picture window at a time, and it controls the window's size and position.

Fallback if this cannot be made to work on a device: on iPad only, run the app in its own window beside the watched app. Switching to the fallback is a change of plan and needs a new decision file.

Status of evidence: not yet verified on a device.

Evidence added 2026-11-12: an earlier version of this ran on a physical iPad; see the device entries under `docs/cases/`. The current version has not run on a device.

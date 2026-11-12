date: 2026-11-12
status: accepted
supersedes: none

# Use Apple's on-device speech recognition and translation instead of a cloud service

Speech is recognized with the system Speech framework and translated with the system Translation framework language packs, with the on-device Apple Intelligence model as a second, switchable translation engine. No audio or text leaves the device.

Why: the app must cost nothing to run and need no account. Captions only have to be good enough to follow a video, so the quality ceiling of the built-in engines is acceptable.

Rejected: a hosted speech or translation API. It would need a network connection, a key, and a recurring cost, which is exactly what this app exists to avoid.

Cost accepted: caption quality is bounded by the system engines, and the required language assets must be downloaded on the device.

date: 2026-11-12
status: accepted
supersedes: none

# Hand audio from the extension to the app through a memory-mapped ring

The broadcast extension converts app audio to 16 kHz mono 16-bit samples and writes them into a ring buffer in a memory-mapped file inside the shared App Group container. The app reads the ring ten times a second. Two flags in the same file carry "a broadcast is running" to the app and "please end the broadcast" to the extension.

Why: the two processes start and stop independently, and the extension can be ended by the system at any time. A mapped file has no connection to set up, keep alive, or repair: a missing writer just looks like a pause. The ring holds ten seconds of audio in about 320 KB, which fits the extension's small memory budget.

Rejected: a local socket or `CFMessagePort` between the two processes, which need connection handling on both sides for no gain here. Rejected: writing audio files for the app to pick up, which adds latency and file churn.

Cost accepted: one writer and one reader only. A reader that falls more than ten seconds behind loses the oldest audio. The App Group capability is required on both targets.

Status of evidence: the ring and the reading path are covered by unit tests and were exercised in the simulator with a synthetic writer. The extension itself has not run on a device.

---
area: log
status: simulated
---

# The captions of the session are readable in the app

- Input: run a session, then return to the app.
- Expected result: below the settings, a list shows every settled sentence of this session with its translation, oldest first. Starting a new session clears it. Closing the app discards it.
- Property: the reader can look back at what was said during the current session, and nothing is kept afterwards.

## Evidence

- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, scripted text standing in for the recognizer: the list showed each sentence with its translation while the session ran. Clearing on a new session and discarding on app close were not checked by hand; the transcript is held in memory only. Simulator only.
- Physical iPad: not run.
- Physical iPhone: not run.

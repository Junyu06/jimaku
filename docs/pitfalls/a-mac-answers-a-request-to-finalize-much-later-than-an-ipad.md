# A Mac answers a request to finalize much later than an iPad

How long the speech analyzer takes to return a final result after `finalize(through: nil)` differs between a Mac and an iPad, enough to hide or fake a change in timing.

- On a physical iPad (Japanese, audio from a screen broadcast), in three logged sessions: about 0.05 seconds, with one request in a hundred taking 0.3.
- On a Mac (macOS 27.2), with the app's recognizer class fed a recording of one of those sessions at its own speed, on the evening of 2026-11-12: about 0.33 seconds for nearly every request, whatever the size of the batches the audio was handed over in (0.03 to 0.1 seconds) and whether the request came after 0.2 or 0.3 seconds of quiet. The request did not return until audio after the pause was let through, which the app does after a quarter of a second.
- Earlier the same day, when the app still waited for the analyzer's volatile range to reach the pause before asking, the Mac answered in 0.03 to 0.07 seconds. That wait was shortened because the range never reaches the pause on the iPad during a broadcast (see `during-a-broadcast-the-speech-analyzers-volatile-range-stops-short-of-the-audio-handed-over.md`).

So a rule that depends on the answer arriving within a tenth of a second works on the iPad and looks broken on the Mac: over a recording the Mac run held 11 of 71 final results and joined none, and showed a gain of 0.06 seconds where an iPad session showed 0.11.

What to do: use a Mac run for what was recognized and how it was cut, never for how long the recognizer or anything after it took. Time is measured from a session logged on a device.

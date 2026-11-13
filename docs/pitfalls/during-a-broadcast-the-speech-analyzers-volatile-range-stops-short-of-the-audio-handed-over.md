# During a broadcast the speech analyzer's volatile range stops short of the audio handed over

`SpeechAnalyzer.volatileRange` does not always end where the audio handed to the analyzer ends. Measured on a physical iPad (Japanese, `SpeechTranscriber` with the progressive preset, 16 kHz 16-bit mono input, so nothing is resampled on the way):

- **With audio from a file, played into the recognizer by the app in the foreground,** the range ended exactly at the audio handed over, within about 0.01 seconds, at each of 67 pauses. A Mac gave the same.
- **With audio from a screen broadcast, the app in the background behind its caption window,** and the audio after a pause held back, the range ended 0.093 seconds before the audio handed over at 66 of 67 pauses, and 0.112 seconds before it at the other. It stayed there for the 1.2 seconds the app waited. Read at once instead of after a wait, it ended 0.139 to 0.149 seconds short.
- The audio captured in that session, played back from a file into the recognizer on the same iPad, in batches of the size the broadcast most often delivered, gave a range that reached the audio handed over. So it is the running conditions that differ, not the audio. Which of them is not known.

Asked to finalize while its range was that short, the analyzer still returned a final result for the speech before the pause within 0.08 seconds.

So a rule of the form "the analyzer has taken the audio in once its volatile range ends at it" did not hold at any pause in the broadcast sessions that were logged. A rule about the analyzer that was measured only with audio from a file was taken to hold for the broadcast as well; it failed at every pause there, and nothing showed it until a session on the device was logged.

What to do instead:

- Do not require the range to reach an exact time. Require it to reach audio that is known not to matter. Before a pause that is the quiet that made the pause: see `PauseDetector.hasSpeech(before:heardTo:)`.
- A timing rule for the recognizer counts as checked only when a session on a physical device, with audio from a broadcast, has been logged with the times of each request and result.

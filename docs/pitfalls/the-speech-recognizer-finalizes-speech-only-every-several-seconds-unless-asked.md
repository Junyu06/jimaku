# The speech recognizer finalizes speech only every several seconds unless asked

`SpeechTranscriber` with the progressive preset decides on its own when a stretch of speech is final, and it is in no hurry. Measured on a Mac (macOS 27.2, Japanese), with a 145-second recording of quick conversation between several speakers played at its own speed:

- It finalized fourteen times, 6 to 17 seconds apart, with as many as 100 characters in one final result.
- Until then all of it was one guess that kept growing. Turns by different speakers ran together with few marks between them.
- Pauses between speakers did not make it finalize, not even one of nearly three seconds.

So "wait for the final result" means waiting ten seconds or more, and the guesses alone do not say where one speaker stopped.

`SpeechAnalyzer.finalize(through:)` changes that. Called with `nil` at a moment of quiet, it made the transcriber report the speech so far as a final result 0.03 to 0.07 seconds later, 60 times in the same recording, and the guesses after it started from nothing. A call when nothing new had been said produced no result. How to call it so that the result ends at the pause is in `asking-the-speech-analyzer-to-finalize-finalizes-all-the-audio-it-has-taken-in.md`.

Also seen in the same measurements: a `SpeechDetector` module added to the analyzer with `reportResults: true` reported nothing while audio was streaming in.

None of this was measured on an iPhone or iPad.

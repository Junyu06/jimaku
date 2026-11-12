# Asking the speech analyzer to finalize finalizes all the audio it has taken in

`SpeechAnalyzer.finalize(through:)` takes a time, but what it finalized in these measurements was whatever audio the analyzer had taken from its input by then. Measured on a Mac (macOS 27.2, Japanese, `SpeechTranscriber` with the progressive preset), with recorded conversation fed in two-second batches that held more than one pause each:

- **A time already passed does not limit it.** With a whole batch handed over and then `finalize(through:)` called with the time of a pause inside the batch, the final result ran on to the end of the batch. It ended in the middle of a phrase, and two pauses in one batch gave one result, not two.
- **A time not reached yet, with no more audio coming, never returns.** With the audio after the pause held back and `finalize(through:)` called with the time of the pause, or 0.01 or 0.1 seconds before it, the call did not return for the rest of a 40-second run and no result came.
- **`nil` right after handing audio over can come too early.** `nil` means the audio the analyzer has taken so far. At the moment a batch was yielded to the input sequence, `analyzer.volatileRange` still ended where the batch began; 0.02 seconds later it ended where the batch did.

What worked, for every pause in the same batches: hand over the audio up to the pause, hold back what follows, wait until `analyzer.volatileRange` ends at the pause, then call `finalize(through: nil)`, and only then hand over the rest. In the pauses that were logged, the volatile range reached the handed-over audio within 0.02 seconds.

- **Even `finalize(through: nil)` does not always return without more audio.** It usually returned within 0.05 seconds. In one run, with audio fed a tenth of a second at a time, a request made after a stretch in which nothing had been recognized did not return; the audio after it was being held back for it, so nothing more was recognized for the remaining two minutes. Holding audio back for a request therefore needs a time limit.

None of this was measured on an iPhone or iPad.

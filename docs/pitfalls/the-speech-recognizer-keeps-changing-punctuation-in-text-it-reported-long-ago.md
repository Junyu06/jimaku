# The speech recognizer keeps changing punctuation in text it reported long ago

Measured on macOS 27.2 with `SpeechTranscriber` and the `progressiveTranscription` preset, 2026-11-12, by playing synthetic speech to it at normal speed:

- With continuous Japanese speech there was no final result for about twenty seconds. Each result until then was a new guess for the whole stretch.
- Guesses came in bursts about a second apart, several within a few milliseconds.
- The words of a guess changed only near its end, and were corrected within the next burst or two: doubled and missing characters appeared in the newest words and were gone a second later.
- Punctuation changed in text reported seconds earlier. A comma first reported eleven seconds in was dropped a second later, came back two seconds after that, and was dropped again by the final result, eleven seconds after it first appeared.
- With English speech that had pauses, a final result came after each sentence or two, and it punctuated differently from the guesses before it.

So nothing may depend on the punctuation, or on character positions, of text the recognizer has not finalized. An earlier version cut every guess into sentences at its periods and translated them; each period that came or went split or merged sentences that were already on screen, and the captions were rewritten in front of the reader.

Positions in speech in progress are counted in spoken characters (letters and digits), which the comings and goings of punctuation do not shift. The recordings are in `JimakuCore/Tests/JimakuCoreTests/RecordedSpeech.swift`.

On a physical iPad the same was seen once, in the owner's screenshots of the earlier version: a period present in one screenshot was gone from the same words in the next.

Not measured beyond that: a physical iPhone or iPad, other languages, real voices.

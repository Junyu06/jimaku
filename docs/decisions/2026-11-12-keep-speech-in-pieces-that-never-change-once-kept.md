date: 2026-11-12
status: accepted
supersedes: the parts of 2026-11-12-translate-speech-while-it-is-still-in-progress.md that make kept sentences follow the recognizer's latest guess

# Keep speech in pieces that never change once kept

While speech goes on, the front of the recognizer's running guess is cut into pieces: a sentence, a clause, or a run of words. In a guess that is not final, a piece is kept once its spoken characters, and all before them, have stood unchanged for 0.8 seconds. A final result is kept at once, whatever of it was not kept yet. A kept piece never changes, whatever the recognizer reports later. It is handed to the translation queue once; if its translation fails and the piece is still among the newest three, it is handed over again. The queue holds three pieces, so when more than that wait at once, for example when a final result brings four sentences together, the oldest is dropped and never translated. The rest of the guess is the speech in progress; it still follows the recognizer and gets a provisional translation.

What is kept is counted in spoken characters (letters and digits), not in characters.

Why: the version before this one rebuilt its sentences from every new guess. On a physical iPad the owner found the result hard to read: the Chinese line kept being rewritten. Playing speech to the system recognizer on a Mac showed why (see `docs/pitfalls/the-speech-recognizer-keeps-changing-punctuation-in-text-it-reported-long-ago.md`). Continuous Japanese went about twenty seconds without a final result, and in that time punctuation inside text reported seconds earlier appeared and disappeared while the words stayed. Every such change redrew the sentence boundaries, so sentences that had been translated and read were split or merged and translated again.

Text that a reader has already read cannot change under them. Live captioning systems settle on a stable beginning for the same reason.

How a piece ends:

- at a sentence ending;
- at a clause mark such as a comma, once enough has been said before it;
- when speech runs on without marks, where a new word starts: between words in English, preferring a joining word such as "and"; in Japanese where kanji or katakana follow hiragana. Japanese with no such place is cut at the limit once it is twice as long.

The limit is about three seconds of speech: 36 columns for Japanese, 60 for English.

Rejected: keeping a piece as soon as it appears. The recognizer corrects its newest words in its next burst of guesses, about a second later; the recordings in the tests show doubled and missing characters that are gone one burst later.

Rejected: locating the kept text by character position. Punctuation that comes and goes shifts every position after it. Counting only spoken characters is not affected.

Rejected: using the times of words to tell kept text from the rest. Where this was measured (Japanese on a Mac, see `docs/pitfalls/speech-results-that-are-not-final-carry-no-word-times.md`), results that were not final carried one time range for the whole text; only final results carried a time for each character.

Cost accepted:

- A correction the recognizer makes to words that are already kept does not reach them. The rest is then taken from the new guess by count, so if the correction changed the number of spoken characters, a character can be repeated or lost at the seam. This did not happen in the two recordings.
- A piece cut where a new word starts is not always a clause, and its translation suffers for it.
- The session log lists pieces, not sentences.
- A guess that becomes shorter than what is kept leaves nothing in progress until it grows again.

Status of evidence: the rules are covered by unit tests, including two recordings of what the system recognizer reported on a Mac for synthetic speech. In both, everything kept stayed as it was and the pieces together said what the final results said. Seen in an iPad simulator with scripted input. Not yet run on a physical device.

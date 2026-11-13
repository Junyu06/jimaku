date: 2026-11-12
status: accepted
supersedes: telling a pause from the recognizer's guesses as the usual way a piece ends, in 2026-11-12-translate-a-sentence-only-when-it-has-ended.md. Its rules stay as the fallback for audio that never goes quiet.

# End a caption where the speaker pauses, by asking the recognizer to finalize

The app listens to the audio it passes to the recognizer. When speech is followed by 0.3 seconds of quiet, it asks the speech analyzer to finalize what it has heard so far. The recognizer answers with a final result for that stretch, and that result is the caption: one thing someone said, translated once.

- Quiet is audio below a tenth of the loudest level heard lately, or below a fixed low level (30 of 32,767) whatever was heard; the loudest level fades to half in five seconds. Less than a tenth of a second of sound is not speech.
- The audio is handed to the analyzer up to the pause, and what follows is held back until the analyzer has taken that audio in and been asked to finalize. So a final result ends at the pause, also when several pauses arrive in one batch of audio. The app waits up to a second for the analyzer to take the audio in; if it has not by then, the pause is let go and the caption ends by the other rules. Once asked, the analyzer gets a quarter of a second; a request that has not returned by then finishes on its own while the audio goes on. Why it has to be done this way is in `docs/pitfalls/asking-the-speech-analyzer-to-finalize-finalizes-all-the-audio-it-has-taken-in.md`.
- Once someone has spoken for 2.5 seconds without such a pause, 0.2 seconds of quiet is enough.
- A final result is cut into its sentences. A sentence that is over is kept whole up to one and a half times the limit (72 columns of Japanese, 108 of English), commas included; a longer one is cut by the rules for speech that runs on.
- The earlier rules still run on the recognizer's guesses: sentence endings, a guess that stops changing, and the limits for speech that runs on. With audio that never goes quiet, such as speech over music, they are the only ones that act.

Why: on a physical iPad with a Japanese video of quick conversation, the version before this one was reported as unusable. Captions came seconds late and were cut in the middle of what someone was saying. Playing the same kind of audio to the recognizer on a Mac showed why.

- Left alone, the recognizer finalized that conversation fourteen times in 145 seconds, 6 to 17 seconds apart, with as many as 100 characters at once.
- Between those, its guesses came about once a second and carried few marks. Short turns by different speakers arrived as one unbroken string, so nothing in the text said where one ended.
- So the earlier rules had only "the guess stopped changing" and "this is getting long" to go by. The first needs a second or two of silence, which quick conversation does not have; the second cuts by length.

Asked to finalize at a pause, the same recognizer returned a final result 0.03 to 0.07 seconds later, at 60 of the 67 pauses found in that recording; at the other 7 it reported nothing. Each was one turn or one sentence, with its own ending mark more often than not. Translating one with the language pack took 0.02 to 0.1 seconds. The first translation was ready 3.2 seconds into the recording instead of 10.7.

Rejected: cutting the guess text at the pause without asking for a final result. A guess carries one time range for all its text (see `docs/pitfalls/speech-results-that-are-not-final-carry-no-word-times.md`), so the text cannot be matched to the moment of the pause, and the guess that covers the pause arrives up to a second later.

Rejected: the analyzer's own speech detector module. Added next to the transcriber with results turned on, it reported nothing while audio was streaming in.

Rejected: a shorter pause for everything. At 0.24 seconds the quick conversation was cut where its own subtitles were, but slower speech pauses that long between phrases, and half a phrase does not translate.

Cost accepted:

- Quiet is told from loudness alone. Speech over music or noise that stays within a tenth of the speech gives no pauses, and captions then come as late and as roughly cut as before.
- A speaker who stops mid-sentence for a third of a second gets the sentence cut there.
- A very short turn is recognized with little around it, and is more often misheard than the same words inside a longer stretch. In two runs over the same recording, a two-syllable question came out right once and as a different word once.
- A finished sentence of up to 72 columns of Japanese may translate into more than the two lines the main row has; the row then shows it in two steps (see 2026-11-12-show-each-sentence-on-a-line-of-its-own.md).
- Sounds that are not speech but are loud and short, such as a knock, cause a request to finalize. Nothing is shown for them unless the recognizer hears words.
- Audio waiting to go to the analyzer is kept without a limit. An analyzer that stays behind for long makes that grow; this was not seen and is not guarded against.

Status of evidence when this was first written: the pause detector, the cutting of final results, and the rows are covered by unit tests. The numbers above are from a Mac, with a 145-second recording of quick Japanese conversation played at its own speed into the app's recognizer class, the pause detector, the transcript, and language-pack translation. The recording is not in the repository. Seen in an iPad simulator with scripted speech. Not yet run on a physical device, where the audio arrives through a screen broadcast.

Evidence added 2026-11-12, from a physical iPad with the audio arriving through a screen broadcast:

- The first build of this decision acted on none of the 67 pauses it found in a 154-second session. It waited for the analyzer's volatile range to end within 0.02 seconds of the pause, and during a broadcast that range stops about a tenth of a second short (see `docs/pitfalls/during-a-broadcast-the-speech-analyzers-volatile-range-stops-short-of-the-audio-handed-over.md`). Each pause held the audio back for 1.2 seconds and was then let go, so captions ended only where the recognizer finalized by itself, 2 to 26 seconds apart.
- The app now takes the analyzer as having the speech before a pause once its range reaches into the quiet that made the pause, 0.16 seconds or less before it. With that, in a 46-second session of the same kind of video, all 19 pauses were acted on at once, each request returned within 0.08 seconds, 17 pauses gave a final result within 0.08 seconds and 2 gave none. The Chinese was ready 0.2 to 0.3 seconds after the pause, 0.6 for the first. The owner reported that a translation now appears as soon as a speaker stops.

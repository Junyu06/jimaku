date: 2026-11-12
status: superseded in part by 2026-11-12-end-a-caption-where-the-speaker-pauses-by-asking-the-recognizer-to-finalize.md (how a pause is told; its rules remain the fallback)
supersedes: the provisional translation and the piece sizes in 2026-11-12-keep-speech-in-pieces-that-never-change-once-kept.md, and the dimmer provisional translation in 2026-11-12-lay-captions-out-in-fixed-lines-that-roll-up.md

# Translate a sentence only when it has ended

Speech in progress is not translated. The translation row shows finished translations only, each shown once and never replaced. While speech is in progress, or kept speech is waiting for the translator or with it, the row ends with a dim "…" if there is room on the line.

A piece of speech is a sentence where one can be told. It ends:

- at a sentence ending;
- where the speaker pauses: when the recognizer reports again and the spoken characters of its guess are still what they were 0.8 seconds before, a burst of guesses has come and brought nothing, and what was said so far is kept as it is. In case the recognizer reports nothing at all during a silence, a guess that has stood for 3 seconds is also taken for a pause; that is checked ten times a second;
- at a clause mark such as a comma, but only after about two seconds of speech (24 columns of Japanese, 36 of English);
- when it runs on with no ending in sight for about four seconds (48 columns of Japanese, 72 of English): where a clause is likely to end (before an English joining word such as "and", after a Japanese form such as から or ので), else where a word starts. A piece may run a quarter past that limit to reach a mark. Text that offers no place where a word starts, such as a long run of hiragana, is not cut until it is twice the limit.

Why: the version before this one cut a piece about every three seconds or at any comma after a few words, and showed a dimmer provisional translation of the unfinished end. On a physical iPad the owner reported two things. The dim text was read like any other, and when its piece was kept the bright text that replaced it said something else. And the pieces were so short and came so fast that a translation was gone or changed before the next could be read.

Both come from translating too early. A translation of half a sentence is a guess, most of all from Japanese, where the verb comes last; and a few words cut off at a comma do not translate into something a reader can use. Marking the guess as dim did not help: a reader cannot not read text on the row they are reading.

Rejected: keeping the provisional translation but drawing it fainter or smaller. It would still be read, and still be replaced.

Rejected: waiting for the recognizer's final result. That was the first version; with continuous speech it left the translation ten seconds or more behind.

Cost accepted:

- The translation of a sentence appears after the sentence has ended and been translated, not while it is spoken. Nothing but the waiting mark shows that more is coming.
- A speaker who pauses in the middle of a sentence gets it cut there.
- A sentence with no mark and no pause still waits about four seconds before it is cut, or up to about eight when it offers no place to cut, and is then cut by rule, not by meaning.
- A piece whose translation fails is tried again only when the recognizer next reports something, and a piece that was with the translator when the user switched engines is not translated at all. Both stay in the session log without a translation.
- The pause is told from the recognizer's guesses, not from the audio, and the guesses trail the speaker. Where it was measured, guesses came in bursts about a second apart, so a pause is seen when it lasts about a second or more. A recognizer that went three seconds between bursts while someone was speaking would have every gap taken for a pause.

Status of evidence: the rules are covered by unit tests. In the replayed recording of continuous synthetic Japanese (five sentences, about twenty seconds), seven pieces were kept, each a sentence or a clause ending in a comma, all before the recognizer's final result. Seen in an iPad simulator with scripted English at medium size. Not yet run on a physical device.

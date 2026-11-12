date: 2026-11-12
status: accepted
supersedes: the requirement "A line is translated once the recognizer has settled on it" in docs/prd/live-translated-captions.md

# Translate speech while it is still in progress

A sentence is translated as soon as it reaches its ending mark inside the recognizer's running guess, without waiting for the recognizer to finalize it. The unfinished end of the speech is translated provisionally and translated again as it grows. Both caption rows run on like a ticker and show their end.

Why: on a physical iPad with a fast-cut Japanese video, the recognizer went ten seconds or more without finalizing anything, because the speaker never paused. Waiting for final results left the Chinese line a sentence or more behind what was being said, which defeats live captions. The owner asked for translation that keeps up.

This is the usual design for live translated captions: re-translate the growing text, keep what has stabilized, and only let the unfinished tail change.

Rejected: waiting for final results, for the reason above. Rejected: translating the whole running guess on every update, which makes the entire translated line flicker and wastes work on text that no longer changes.

Cost accepted: a sentence that settles early is not corrected if the recognizer later revises it; the text after it is still kept, by tracking how much of the stretch has settled rather than how many sentences. Sentence endings in English are found by rule, so an unusual abbreviation can still cut a sentence early. The provisional translation of the unfinished end changes as more is said.

Status of evidence: the sentence splitting, the transcript, and the pipeline are covered by unit tests, and the behavior was seen in an iPad simulator with scripted speech. The first version, which waited for final results, ran on a physical iPad; this version has not yet been checked there.

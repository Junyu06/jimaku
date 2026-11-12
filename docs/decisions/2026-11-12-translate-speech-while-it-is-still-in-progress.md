date: 2026-11-12
status: accepted
supersedes: the requirement "A line is translated once the recognizer has settled on it" in docs/prd/live-translated-captions.md

# Translate speech while it is still in progress

A sentence is translated as soon as it reaches its ending mark inside the recognizer's running guess, without waiting for the recognizer to finalize it. The unfinished end of the speech is translated provisionally and translated again as it grows. Both caption rows run on like a ticker and show their end.

Why: on a physical iPad with a fast-cut Japanese video, the recognizer went ten seconds or more without finalizing anything, because the speaker never paused. Waiting for final results left the Chinese line a sentence or more behind what was being said, which defeats live captions. The owner asked for translation that keeps up.

This is the usual design for live translated captions: translate the growing text again as it grows, and reuse what did not change.

Rejected: waiting for final results, for the reason above. Rejected: translating the whole running guess on every update, which makes the entire translated line flicker and wastes work on text that no longer changes.

Until the recognizer finalizes a stretch of speech, the stretch's sentences are exactly the sentences of its latest guess. If the recognizer rewrites a sentence, the entry changes with it and is translated again; a sentence that did not change keeps its translation.

Rejected: treating a sentence as fixed once it has been translated and locating the rest of the speech after it. The recognizer can rewrite, shorten, or lengthen text it already reported, and two rounds of review kept finding rewrites for which any way of locating "the rest" lost or repeated words.

Cost accepted: a Chinese sentence that was already shown changes whenever the recognizer rewrites its source before finalizing, which can happen more than once. A sentence whose translation fails after its stretch is final is not retried. The provisional translation of the unfinished end changes as more is said. Sentence endings in English are found by rule, so an unusual abbreviation can still end a sentence early.

Status of evidence: the sentence splitting, the transcript, and the pipeline are covered by unit tests, and the behavior was seen in an iPad simulator with scripted speech. The first version, which waited for final results, ran on a physical iPad; this version has not yet been checked there.

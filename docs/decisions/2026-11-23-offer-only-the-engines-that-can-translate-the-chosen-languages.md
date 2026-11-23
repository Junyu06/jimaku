date: 2026-11-23
status: superseded in part by 2026-11-23-list-both-engines-and-grey-out-the-one-that-cannot-translate-with-the-reason.md: an engine that cannot translate the pair is now listed greyed out, and the choice of engine is always shown. The rest stands.
supersedes: none

# Offer only the engines that can translate the chosen languages

The settings offer the language-pack engine when the Translation framework reports the chosen pair as installed or as supported, and the Apple Intelligence engine when the on-device model works in both languages. The engine the user chose is used when it can translate the pair; otherwise the other one is. With one engine left, the choice of engine is not shown.

A device that can never run the model is not offered it. A device where the model is switched off or still being downloaded is: starting a session then says what is wrong, and suggests the language packs for as long as they can translate the pair.

When the engine in use changes while a session runs, because the user chose another or because the system reported something new, the session's translator is prepared again with the new one. Choosing the engine that is already in use prepares nothing again.

Why: with ten languages, not every pair can be translated by both engines. The model does not work in Hindi, and a language pack may not exist for a pair. An engine that cannot work should not be there to choose.

Status of evidence: the rules are covered by tests of JimakuCore. In an iPad simulator, where every pair is reported as ready for both engines, the engine was changed during a session both ways, and the next captions came from the other engine; see `docs/cases/translation-002-apple-intelligence-translates-captions.md`. A pair with only one engine has not been seen on a device.

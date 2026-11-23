---
area: translation
status: not-run
---

# When the on-device model cannot be used the app says why and shows original captions

- Input: on a device where Apple Intelligence is switched off in the system's settings, choose a pair of languages both engines can translate, set 翻译引擎 (translation engine) to Apple Intelligence, and start a session.
- Expected result: the floating window shows original-language captions. The app shows a message saying Apple Intelligence is not switched on, and that the engine can be changed to the language packs.
- Property: a model that is unavailable is reported as such, and the other engine is pointed to when it can translate the pair.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- The simulator uses the host Mac's model, which was available, so this was not produced there. A pair the language packs cannot translate, where the message must not point to them, is not a case yet.

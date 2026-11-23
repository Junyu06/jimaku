date: 2026-11-23
status: accepted
supersedes: in 2026-11-23-offer-only-the-engines-that-can-translate-the-chosen-languages.md, that an engine which cannot translate the pair is left out of the settings and that the choice of engine is hidden when one engine is left. Which engine a session uses, and when its translator is prepared again, stay as decided there.

# List both engines and grey out the one that cannot translate with the reason

The settings always show the choice of engine, with both engines in it. An engine that cannot translate the languages in use on this device is greyed out and cannot be chosen, and the reason stands after its name in the same line:

- the device can never run the on-device model;
- the model does not work in one of the two languages, and which one, the spoken one first;
- the system has no language pack for the pair.

Before the device has answered, nothing is greyed out.

Why: the owner asked for it on 2026-11-23, after trying the settings on an iPad: an engine that is missing from the list leaves the user wondering where it went, while one that is greyed out with "not supported on this device" answers the question. Hiding the whole row had the same fault.

Rejected: a second line under the engine's name for the reason. A menu made by a picker shows only one line; the second was not drawn in an iPad simulator.

Unchanged: a device where the model is switched off or still being downloaded can run it, so the engine is not greyed out there, and starting a session says what is wrong.

Status of evidence: the rules are covered by tests of JimakuCore. In an iPad simulator, where the model asked is the host Mac's, choosing Hindi as the spoken language greyed out Apple Intelligence with the reason, and tapping it chose nothing. A device that can never run the model has not been seen.

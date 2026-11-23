date: 2026-11-23
status: accepted
supersedes: in 2026-11-23-offer-only-the-engines-that-can-translate-the-chosen-languages.md, that an engine which cannot translate the pair is left out of the settings, that a device which can never run the model is not offered it, and that the choice of engine is hidden when one engine is left. Which engine a session uses, and when its translator is prepared again, stay as decided there.

# List both engines and grey out the one that cannot translate with the reason

The settings always show the choice of engine, with both engines in it. An engine that cannot translate the languages in use on this device is greyed out and cannot be chosen, and the reason stands after its name in the same line:

- the device can never run the on-device model;
- the model does not work in one of the two languages, and which one, the spoken one first;
- the system said it has no language pack for the pair;
- the system gave no answer: it was not asked about the pair's language pack, or the model named no language at all. No reason is made up for what was not reported.

A choice of an engine that has something in its way is not taken, wherever it comes from, and the engine chosen before stays chosen.

When neither engine can translate the languages in use, there is no engine in use, and the row says that these two languages cannot be translated now, in place of a list with a greyed-out line marked as chosen. The engine the user chose is kept for when one can.

Before the device has answered, both engines are listed and neither is greyed out. The rows for the two languages show only the stored choice until then, as before.

Why: the owner asked for it on 2026-11-23, after trying the settings on an iPad: an engine that is missing from the list leaves the user wondering where it went, while one that is greyed out with "not supported on this device" answers the question. Hiding the whole row had the same fault.

Rejected: a second line under the engine's name for the reason. A menu made by a picker shows only one line; the second was not drawn in an iPad simulator.

Unchanged: being switched off or still being downloaded does not by itself grey the model's engine out; starting a session says what is wrong. What the model reports about its languages in those states has not been seen, and if it names none, the engine is greyed out as not reported.

Status of evidence: the rules are covered by tests of JimakuCore. In an iPad simulator, where the model asked is the host Mac's, choosing Hindi as the spoken language greyed out Apple Intelligence with the reason; tapping it left the engine chosen before, the language packs, as the stored choice. A device that can never run the model, a pair with no language pack, and the row with no engine usable have not been seen.

date: 2026-11-23
status: accepted
supersedes: none

# Ask the model to translate under the guardrails for content transformations

The Apple Intelligence engine prepares its translator with `SystemLanguageModel(guardrails: .permissiveContentTransformations)`, not with `SystemLanguageModel.default`, and asks that model whether it is available and works in the two languages. The settings still ask the default model which languages to offer.

If the model throws a refusal all the same, the sentence is handled like any sentence whose translation failed, as before. The error's description then says that Apple Intelligence did not translate the sentence, in place of the system's own; a session shows it where it shows any translation error, when no other notice stands before it.

Why: with its default guardrails the model refused to translate sentences for what they were about, and a caption has to say what the speaker said. The system offers the permissive guardrails for turning text into other text. On a Mac, sentences the default guardrails refused were translated under the permissive ones each time they were tried; see `docs/pitfalls/the-on-device-model-refuses-to-translate-sentences-its-default-guardrails-object-to.md`.

Rejected for now: handing a refused sentence to the language packs, and treating a thrown refusal as final for its sentence so that the window keeps its translation row. Both were written and then taken out before the branch was pushed. Apple documents that under these guardrails a request for text does not throw a guardrail error, and none was thrown on a Mac, so the rules would have been for an event nobody has seen. They also needed answers that are not there yet: what to do with a refusal that arrives for speech still being held, or after an ordinary failure, and whether the engine the settings call the language packs is itself the model on a given device (see `docs/pitfalls/the-translation-framework-answers-by-a-default-strategy-that-changed-with-the-sdk.md`). A refusal thrown on a device under these guardrails would be the evidence to design them with.

Cost accepted: where the permissive guardrails let a sentence through, the app shows the model's translation of a sentence the default guardrails might have kept back.

Status of evidence: measured on a Mac, with the app's own translator code and sentences written for the test; see `translation-006` and `translation-007` under `docs/cases/`. What the guardrails do on an iPad or iPhone, and that the app's message is what a session shows there, have not been run.

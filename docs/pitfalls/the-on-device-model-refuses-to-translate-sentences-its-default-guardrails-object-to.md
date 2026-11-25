# The on-device model refuses to translate sentences its default guardrails object to

`SystemLanguageModel.default` checks what it is asked and what it answers against the system's guardrails. A sentence they object to is not translated: `respond(to:)` throws, with the description "The model's safety guardrails were triggered." The sentences refused here were statements about a war, a man hitting his wife, and a video game.

Seen on a physical iPad on 2026-11-23, reported by the owner with a screenshot: in a session with Chinese spoken, English as the target, and the Apple Intelligence engine, the app showed that description, in English on an interface in Chinese, as a translation error. The app counts translation as unavailable from a failed sentence until a later one is translated, so the floating window, set to show the translation only, showed the original Chinese meanwhile.

Measured on one Mac (macOS 27.2) on 2026-11-23, with Mandarin sentences written for the test, each handed over once as text in a fresh session:

- First run, a test program with a copy of the app's instructions that named the spoken language "Chinese", ten sentences. With the default guardrails five were refused: an overdose of a medicine that can kill, a politician calling immigrants criminals, civilians and children killed in a war, a man hitting his wife, and shooting zombies in a video game. A sentence about a stabbing in the news and one about a film's villain and a bomb were among the five translated. With `SystemLanguageModel(guardrails: .permissiveContentTransformations)` all ten were translated.
- Second run, the app's own translator code and instructions, which name the spoken language "Simplified Chinese", those five sentences. With the default guardrails the first two were translated and the other three refused again. As the app prepares the model, all five were translated.
- Two sentences refused in the first run were translated in the second. The runs differed in the name the instructions gave the spoken language, so this does not show whether one and the same prompt is refused only some of the time.
- The error thrown was the case `guardrailViolation` of `LanguageModelError`, a type that exists from iOS and macOS 27. `LanguageModelSession.GenerationError` has a case of the same name and is the earlier type, deprecated in 27. Which one an iPad throws has not been seen.

What this means here:

- Translate with the model made by `SystemLanguageModel(guardrails: .permissiveContentTransformations)`. Apple's documentation describes it as guardrails for turning text input, unsafe content included, into text responses, with summarizing a news article as its example, and says that in this mode a request that generates a `String` does not throw a guardrail error. A request for anything other than a `String` is checked as by default, so do not move the translation to guided generation.
- That is what the documentation says and what one Mac did. On an iPad nothing about it has been measured, and the app runs on systems from 26.0.
- Do not show the system's description to the user. Where it was seen it was in English on an interface in Chinese, and it reads as if the user had done something unsafe.
- Do not test this with a clip that was not made for it. Whether it contains a sentence the default guardrails refuse is not known beforehand, and a refused sentence that is tried again may go through.
- In the permissive mode the model can still decline in words: the same documentation says it may answer with a refusal message as its text. Nothing is thrown then, and the app shows that text as the translation. See `the-on-device-model-answers-a-caption-that-reads-as-a-request-instead-of-translating-it.md`.

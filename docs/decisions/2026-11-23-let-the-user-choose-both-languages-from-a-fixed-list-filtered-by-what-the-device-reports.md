date: 2026-11-23
status: accepted
supersedes: none

# Let the user choose both languages from a fixed list, filtered by what the device reports

The app has one list of languages: English, Japanese, Chinese, Korean, Spanish, French, German, Italian, Portuguese, and Hindi. The user chooses one as the spoken language and one as the language captions are translated into. Chinese is listened for as Mandarin, which the recognizer writes in simplified characters, and translated into as Simplified or Traditional.

When the app opens or comes back to the front, it asks the system which of the languages the speech recognizer knows, what the Translation framework says about each pair, and which languages the on-device language model works in. One round of questions waits for the one before it, so their answers arrive in order. The settings offer a spoken language when the device recognizes it and some engine can translate it into something, and a target when something can be translated into it.

Why: the owner asked for speech in Chinese to be captioned, for a choice of what captions are translated into, and for the choice to follow what the device can do. These ten are the languages that both the system speech recognizer (`SpeechTranscriber`) and the Translation framework reported to a test program on macOS 27.2 on 2026-11-23.

Rejected: offering every locale the device reports. The recognizer reported 45 locales, most of them regional forms of the same ten languages, and a language needs more than the device can tell: rules for cutting its speech into captions, and a name to give the language model.

Rejected: detecting the spoken language. The recognizer takes one locale when it starts.

Rejected: Cantonese and the Indian languages other than Hindi, which the recognizer reported and the Translation framework did not; and Russian, Arabic, Thai, Vietnamese, and the others the Translation framework reported and `SpeechTranscriber` did not. `DictationTranscriber` reported some of the latter. The way this app ends a caption was built on how `SpeechTranscriber` reports speech, and nothing here was tried on the other.

Cost accepted:

- The list is in the code. A language the system gains later needs a new version of the app.
- Speech in the new languages is cut by borrowed rules: the Japanese ones for Chinese and Korean, the English ones for the rest. Those rules were tuned on Japanese and English; the numbers in them count columns, and nothing was measured for the other languages.
- Each language has one recognizer locale: Spain for Spanish, Brazil for Portuguese, mainland China for Chinese. Whether another regional form recognizes a given speaker better was not tried.
- The text sizes and the number of lines were chosen for Chinese translations. A translation into a language written in narrow letters takes more columns; how many lines that needs was not measured.
- In the simulator the recognizer is scripted: every language other than Japanese replays the English speech. Its language-pack engine is scripted too and gives Simplified Chinese whatever the target; its Apple Intelligence engine is the host Mac's model and follows the target.

- What the Translation framework says about a pair depends on a default the app does not set; see `docs/pitfalls/the-translation-framework-answers-by-a-default-strategy-that-changed-with-the-sdk.md`.

Status of evidence: the list and what is offered are covered by tests of JimakuCore. Nothing has run on a device, so what a device reports has not been seen. See the `language-` cases under `docs/cases/`.

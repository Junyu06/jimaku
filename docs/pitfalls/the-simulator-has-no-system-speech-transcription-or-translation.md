# The simulator has no system speech transcription or translation

Measured on the iOS 27.0 simulator runtime (iPhone 17 and iPad mini (A17 Pro)), 2026-11-12:

- `SpeechTranscriber.isAvailable` is `false`, and its supported and installed locale lists are empty.
- `LanguageAvailability().status(from:to:)` returns `.unsupported` for English to Simplified Chinese and for Japanese to Simplified Chinese.
- `SystemLanguageModel.default.availability` is `.available`.

So on that runtime neither on-device speech recognition nor these Translation framework language pairs could be run in the simulator, while the Apple Intelligence model could. Other runtimes and language pairs were not measured. Code that depends on recognition or language-pack translation is verified on a physical device; in the simulator it is driven by scripted input instead.

---
area: speech
status: not-run
---

# Speech in a video appears as original-language captions

- Input: on a device, pick 英语 (English), tap 开始 (Start), confirm the screen broadcast, play an English video in a video app. Repeat with 日语 (Japanese) and a Japanese video.
- Expected result: the floating window shows what is being said, in the spoken language. Text grows while a sentence is spoken and settles when it ends. It roughly keeps up with the speaker.
- Property: audio captured from another app is recognized on the device by the system speech model while the app is in the background.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, with scripted text standing in for the recognizer (the simulator has no system speech model): text grew word by word and settled in the floating window while Safari was in front. This exercises the transcript and the window, not speech recognition.
- 2026-11-12: the app including `SystemSpeechRecognizer` compiles for `generic/platform=iOS`. It has never run.

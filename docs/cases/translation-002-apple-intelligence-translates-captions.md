---
area: translation
status: simulated
---

# Apple Intelligence translates captions

- Input: set 翻译 (Translation) to Apple Intelligence, start a session, and let it run. Switch back to 语言包 (language packs) while the session runs.
- Expected result: each kept piece of speech gets a Simplified Chinese line produced by the on-device model. Switching the engine during a session keeps captions coming. If the model is unavailable, the app says so and keeps showing original-language captions.
- Property: the translation engine can be chosen and changed without restarting the session.

## Evidence

- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, scripted text standing in for the recognizer: with Apple Intelligence selected, the model translated each scripted sentence (for example "The window should stay on top." became "窗口应该保持在顶部。"). The translations differ from the scripted ones, so they came from the model. Switching the engine during a session was not exercised. Simulator only; the simulator uses the host Mac's model.
- Physical iPad: not run.
- Physical iPhone: not run.

---
area: translation
status: simulated
---

# Apple Intelligence translates captions

- Input: with a pair of languages that both engines can translate, set 翻译引擎 (translation engine) to Apple Intelligence, start a session, and let it run. Switch back to 语言包 (language packs) while the session runs.
- Expected result: each kept piece of speech gets a line in the chosen language produced by the on-device model. Switching the engine during a session keeps captions coming, from the other engine.
- Property: the translation engine can be chosen and changed without restarting the session.

## Evidence

- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, scripted text standing in for the recognizer: with Apple Intelligence selected, the model translated each scripted sentence (for example "The window should stay on top." became "窗口应该保持在顶部。"). The translations differ from the scripted ones, so they came from the model. Switching the engine during a session was not exercised. Simulator only; the simulator uses the host Mac's model.
- 2026-11-23, same simulator, with 中文 into 英语 chosen and scripted English text standing in for the recognizer: the session started with 语言包, whose scripted captions are Simplified Chinese; after switching to Apple Intelligence during the session, the next captions were English sentences, so they came from the model, and it had been told the chosen target. In a second session started with Apple Intelligence, its captions were English, and after switching to 语言包 the next ones were the scripted Simplified Chinese. Simulator only.
- What the app says when the model is unavailable is in translation-005.
- Physical iPad: not run.
- Physical iPhone: not run.

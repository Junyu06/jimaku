---
area: language
status: not-run
---

# A device that can do no pair does not start a session and says why

- Input: on a device where the system's speech recognizer is not available, so that the app is told it can caption no pair of languages, open the app, wait a moment, and tap 开始 (start).
- Expected result: no floating window opens and the button stays on 开始. The app shows a message naming the spoken language and the target and saying a session cannot start. The two language rows still show the stored choice.
- Property: when the system has answered that nothing can be captioned, the app refuses to start instead of starting a session that fails.

## Evidence

- Physical iPad: not run. No device at hand reports this.
- Physical iPhone: not run.
- The simulator reports every language as ready, so this was not produced there. When a session can start is covered by tests of JimakuCore (`LanguageSettings.canStart`).

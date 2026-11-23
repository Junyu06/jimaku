---
area: language
status: not-run
---

# A session started without its language pack shows original captions and translates once the pack arrives

- Input: on a device, choose a pair of languages whose language pack is not downloaded, with the language-pack engine in use. Start a session without downloading and play a video. Return to the app, tap 下载 (download), and confirm the system's sheet.
- Expected result: the floating window shows original-language captions, and the app shows a message naming the two languages whose pack is missing. After the download finishes, translations start appearing in the same session: by themselves if the app is still looking for the pack (see language-005 for how long it looks), otherwise the next time the app comes to the front.
- Property: a session does not need to be restarted to pick up a language pack that arrives while it runs.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- When a session's translator is prepared again is covered by tests of JimakuCore (`LanguageSettings.needsPreparingAgain`). The simulator has no language packs, so the session itself could not be run there.

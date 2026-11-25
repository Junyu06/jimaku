---
area: language
status: not-run
---

# A missing language pack can be downloaded from the settings

- Input: on a device, choose a pair of languages whose language pack is not downloaded, with the language-pack engine in use. Tap 下载 (download) on the row that appears and confirm the system's sheet. Wait for the download, then start a session.
- Expected result: a row saying 语言包未下载 (the language pack is not downloaded) appears in the settings with a 下载 button. The button brings up the system's download sheet. When the download has finished while the app is still looking for it, the row goes away without leaving the app; the app looks for eleven minutes or somewhat more after the sheet closes. A download that finishes after that shows as finished the next time the app comes to the front. The session then translates.
- Property: a missing language pack is found before a session and can be fetched without leaving the app.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- The simulator has no language packs and reports every pair as ready, so the row never appears there. The code that asks for the download compiles for a device and for the simulator and has not been run anywhere. Cancelling the sheet, and a download that fails, are also not run. On a device where the Translation framework reports every pair as installed the row cannot appear; see `docs/pitfalls/the-translation-framework-answers-by-a-default-strategy-that-changed-with-the-sdk.md`.

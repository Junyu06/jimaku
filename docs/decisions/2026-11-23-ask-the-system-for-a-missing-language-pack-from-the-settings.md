date: 2026-11-23
status: accepted
supersedes: none

# Ask the system for a missing language pack from the settings

When the language-pack engine is in use and the system offers a pack for the chosen pair that is not downloaded, the settings show a row saying so, with a button. The button brings up the system's own sheet, which asks before it downloads. The sheet can close while the download goes on. So when it closes the app asks the system about that pair at once, and again after each of twenty waits of three seconds and then forty waits of fifteen, and stops as soon as the pack is no longer waiting to be downloaded. Each look also waits for the system's answer, so the looking lasts eleven minutes or somewhat more; no exact time is promised. A download that finishes after the last look is noticed the next time the app comes to the front. Each pair asked for is looked for on its own, so asking for a second pack does not stop the looking for the first. An error from the sheet is kept with the pair it was for, and is shown, ahead of the message about a missing pack, while that pair is the one in use and its pack is still not downloaded.

A session that is running without its pack gets its translator prepared again once the pack is reported installed: when the pack was not known to be installed as the translator was prepared, or when preparing it failed because the pack was missing.

Why: until now a missing pack was reported only after a session had started, with instructions to find the download in the system's settings. That was acceptable with two languages the owner had already downloaded, and is not with ten.

Rejected: downloading without asking. The Translation framework downloads a pack only through its own sheet.

Cost accepted: none of this could be run. The simulator has no language packs, so the row never appears there. What the sheet reports when the user cancels it, and how long a download takes to show as installed, are not known; a message may appear after a cancel. On a device where the Translation framework's default strategy does not use the downloaded packs, the row never appears either; see `docs/pitfalls/the-translation-framework-answers-by-a-default-strategy-that-changed-with-the-sdk.md`.

Status of evidence: when a translator is prepared again is covered by tests of JimakuCore. Everything else is not run; see `docs/cases/language-005-a-missing-language-pack-can-be-downloaded-from-the-settings.md`.

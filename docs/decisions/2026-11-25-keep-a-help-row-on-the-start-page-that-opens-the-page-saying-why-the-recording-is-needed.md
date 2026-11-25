date: 2026-11-25
status: accepted
supersedes: none

# Keep a help row on the start page that opens the page saying why the recording is needed

Under the settings the start page has a section 帮助 (Help) with one row, 为什么要打开录屏 (why open the recording). It is there in every state of the page and brings up the page that says why the recording is needed.

Why: that page comes by itself once, before the first session, and the line with the question mark shows only while a session runs with no recording. The owner, after the first run on an iPad, said that someone who did not take it in the first time has to be able to read it again, and left where to the app. A row of its own under the settings is where the system's own settings put a link to an explanation, and it does not move when the page's state changes.

Closing the page from this row with its button, 确认, counts as having read it, as it does from the line with the question mark: a first tap on Start after that starts the session at once. See `docs/decisions/2026-11-25-show-the-page-that-says-why-the-recording-is-needed-once-before-the-first-session.md`.

Rejected: a question mark in a bar at the top of the page. The page has no such bar, and would get one for this alone.

Rejected: keeping the line with the question mark under the main button in every state. Under Start, before any recording was asked for, a line about the recording answers a question nobody has yet.

Status of evidence: seen in an iPad simulator; see `docs/cases/audio-011-the-help-row-brings-up-the-page-that-says-why-the-recording-is-needed-with-no-session-running.md`. Not run on a device. The owner has not seen the row.

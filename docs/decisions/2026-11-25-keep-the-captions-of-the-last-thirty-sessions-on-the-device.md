date: 2026-11-25
status: accepted
supersedes: 2026-11-12-keep-the-session-captions-in-memory-only.md

# Keep the captions of the last thirty sessions on the device

Each session's captions, the original and the translation of every kept piece of speech, are written to the device. The newest thirty sessions are kept; a thirty-first deletes the oldest. A page of the app, 字幕记录 (Caption History), lists them by when they started, with their two languages and their first line; one can be opened and read or deleted, and all can be deleted at once after a question that says they cannot be brought back.

Why: the owner asked for captions to be kept, the last thirty sessions. Until now the captions of a session were gone when the next one started or the app closed.

How:

- One file for each session, in a folder of the app's own under Application Support. The folder is marked as left out of the device's backups: what was watched stays on this device unless the user exports it.
- A session in which nothing was said is not kept.
- Which sessions are kept, in what order, and which leave are rules of JimakuCore (`CaptionArchive`). The app does the reading and writing.
- An older session makes room only once the new one is on the device: a write that failed deletes nothing and is tried again.
- A session is deleted from the device first and taken off the list only when it is gone. Any text file made of it for sharing is deleted with it; one that could not be removed does not keep the session listed, and is removed when the app next starts. Deleting all deletes the folder itself, with the files that could not be read or are no longer listed, and lists again what is left. The row that deletes all is there whenever the device holds any such file, or a folder of them that cannot be listed, also under an empty list.
- Deleting what is saved of the session that is running, or deleting all while one runs, deletes what was said so far; what is said afterwards is saved as a session of its own. What is being said at that moment goes with what was deleted: saving starts again at the first caption after the recognizer has settled what was being said, which is mostly where the speaker next pauses. Speech heard before the deletion whose text arrives after it is saved: the second part of a sentence the recognizer settles in two parts, or a short sentence it had not yet shown anything of. The app cannot tell when the words of a caption were spoken. The captions of the session that runs or has just ended stay on the start page, under 本次字幕, until the next session starts; deleting what is saved does not clear that page. A session still owed a write is not written after it was deleted.
- One session is deleted by a swipe on its row, which asks nothing, as the system's lists do, or from its own page, which asks first. Deleting all is a row at the end of the list, not a button in the bar at the top, where a finger looking for the way back would find it.

Rejected: one file holding every session. It would be written whole at every save, and thirty long sessions are several megabytes.

Cost accepted: a file that cannot be read, or that is not named after the session it holds, is skipped, not shown, and not deleted. A write that fails (a full device) is logged and tried again at the next save; the user is not told, and a session still owed when the app is closed is lost. A session that cannot be deleted stays on the list, and the user is not told why.

When a running session is written is in `2026-11-25-write-a-running-sessions-captions-every-ten-seconds-and-when-the-app-leaves-the-front.md`; export is in `2026-11-25-export-a-saved-session-as-plain-text-with-each-original-over-its-translation.md`.

Status of evidence: the rules are covered by tests of JimakuCore. In an iPad simulator a session's captions were listed after it ended, were still there after the app was installed again and opened, opened to the same lines, and were gone after deleting all; a swipe on a row showed its delete button, and deleting a session from its own page removed its row and its file. See the `log-` cases under `docs/cases/`. Not run on a device. Not tried by hand anywhere: the thirty-first session, a write or a deletion that fails, and deleting while a session runs.

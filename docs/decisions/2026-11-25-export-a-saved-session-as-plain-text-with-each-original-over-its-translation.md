date: 2026-11-25
status: accepted
supersedes: none

# Export a saved session as plain text with each original over its translation

A saved session's page has one button that hands the session to the system's share sheet as a text file. The file is named `Jimaku`, the date, and the time the session started. It holds each piece's original, its translation under it, and an empty line; a piece that got no translation has its original alone.

Why: the owner asked for export as TXT. The share sheet is where the system lets a file be saved to Files or sent to another app, so the app needs no export page of its own.

How: the text and the name are rules of JimakuCore (`SavedSession`). The file is written only when the share sheet asks for it, into a temporary folder of that session's own, so two sessions that started in the same minute do not share a file. These copies are deleted with their session and all of them when the app starts.

Rejected: caption file formats with times (SRT and the like). The owner asked for plain text, and the kept pieces carry no times.

Status of evidence: the text and the name are covered by tests of JimakuCore. In an iPad simulator the button brought up the share sheet with the file's name and Save to Files, and the file was in its folder; what the file holds was read in an earlier build, which wrote it when the page opened; see `docs/cases/log-003-exporting-a-saved-session-gives-a-text-file-with-each-original-over-its-translation.md`. Saving to Files was not done. Not run on a device.

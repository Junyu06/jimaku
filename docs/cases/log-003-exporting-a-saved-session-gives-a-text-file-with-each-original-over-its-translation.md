---
area: log
status: simulated
---

# Exporting a saved session gives a text file with each original over its translation

- Input: in an iPad simulator, open a saved session from the list of earlier sessions and tap the share button at the top of its page.
- Expected result: the system's share sheet comes up for a file named `Jimaku`, the date, and the time the session started, ending in `.txt`, and offers Save to Files. The file holds for each piece its original line, its translation on the next line when it has one, and an empty line.
- Property: a session can leave the app as plain text.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0: the share sheet came up for `Jimaku 2026-11-25 0320.txt` with Save to Files, and that file was in a folder of the session's own under the app's temporary folder. An earlier build wrote `Jimaku 2026-11-25 0316.txt` with each original over its translation. Save to Files was not tapped. A simulation.
- The text and the name are covered by tests of JimakuCore (`SavedSession`).
- Physical device: not run.

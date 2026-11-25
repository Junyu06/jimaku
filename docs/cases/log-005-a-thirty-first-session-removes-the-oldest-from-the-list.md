---
area: log
status: not-run
---

# A thirty-first session removes the oldest from the list

- Input: with thirty saved sessions, run one more session in which something is said, and open the list of earlier sessions.
- Expected result: the list has thirty rows; the new session is first and the session that was oldest is gone, and so is its file.
- Property: the app keeps a bounded amount of what was watched.

## Evidence

- Not run in the app anywhere. The rule is covered by tests of JimakuCore (`CaptionArchive`): keeping a thirty-first session drops the oldest and names it for deletion.

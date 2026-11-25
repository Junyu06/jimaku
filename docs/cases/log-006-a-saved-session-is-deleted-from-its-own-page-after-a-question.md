---
area: log
status: simulated
---

# A saved session is deleted from its own page after a question

- Input: in an iPad simulator with two saved sessions, open one from 字幕记录, tap the bin at the top of its page, and tap 删除 (Delete) in the question that comes up.
- Expected result: the question reads 删除这次字幕？ with a red 删除. After it, the page closes, the list has the other session alone, and the deleted session's file is gone from the app's folder.
- Property: one session can be removed where it is read, and not by a slip of the finger.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0, interface in Chinese: the question came up from the bin with its red button; after 删除 the folder held one file where it had held two. A simulation.
- A swipe on a row of the list showed a red 删除; it was not tapped.
- Physical device: not run.

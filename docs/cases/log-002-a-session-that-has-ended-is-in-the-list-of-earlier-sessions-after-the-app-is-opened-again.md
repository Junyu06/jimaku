---
area: log
status: simulated
---

# A session that has ended is in the list of earlier sessions after the app is opened again

- Input: in an iPad simulator, run a session until several captions have appeared, tap 停止 (Stop), quit the app, open it again, and tap 字幕记录 (Caption History).
- Expected result: the list has one row for that session, with the date and time it started, its two languages (`英语 → 简体中文`), and its first line. Tapping the row shows every piece of that session, original over translation, oldest first.
- Property: a session's captions outlive the session and the app's process.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0, scripted text standing in for the recognizer: after a session of some forty seconds the list had its row; after the app was installed again and launched, in English, the row was still there (`English → Chinese, Simplified`); the row opened to the session's lines. The page was then named 以前的字幕 and its rows had no first line; with the present name and rows the list was looked at again with two sessions. A simulation.
- Physical device: not run.

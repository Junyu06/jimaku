---
area: log
status: simulated
---

# Deleting all saved sessions asks first and leaves the list empty

- Input: in an iPad simulator with one saved session, open the list of earlier sessions, tap 全部删除 (Delete All) at the end of the list, and confirm.
- Expected result: before anything is deleted a question comes up that says the captions saved on this device will be deleted and cannot be brought back, with a red button that deletes and a way out. After confirming, the list is empty and says 暂无字幕记录 (No Caption History), and the row 全部删除 is gone.
- Property: everything saved can be removed in one step that cannot happen by a slip of the finger.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0, interface in English: the question came up with its red button; after confirming, the list was empty with that text and the button greyed out. In that run the question hung from the bottom of the page; it was then moved onto the button, and with the interface in Chinese it came up from the button. Both runs were of a build that had the button in the bar at the top, reading 全部清空. With the present row at the end of the list, in Chinese: the question 删除全部字幕？ came up from the row with its red 全部删除, and after it the app's folder of saved sessions was empty. A simulation.
- Physical device: not run.

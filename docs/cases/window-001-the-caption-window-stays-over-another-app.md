---
area: window
status: simulated
---

# The caption window stays over another app

- Input: open the app, tap 开始 (Start), switch to another app.
- Expected result: a floating window with caption text appears and stays on screen above the other app. Its text keeps changing every two seconds. Audio playing in the other app is not interrupted. Returning to the app and tapping 停止 (Stop) removes the window and the button reads 开始 again.
- Property: captions can be shown above other apps through Picture in Picture, and the app keeps updating them while it is in the background.

## Evidence

- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0: after tapping 开始 and opening Safari, the window stayed above Safari and showed a different demo caption four seconds later. Back in the app, tapping 停止 removed the window and the button read 开始. Whether other apps' audio is interrupted was not checked. Simulator only.
- Physical iPad: not run.
- Physical iPhone: not run.

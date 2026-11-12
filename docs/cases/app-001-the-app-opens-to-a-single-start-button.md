---
area: app
status: simulated
---

# The app opens to a single Start button

- Input: install the app and open it from the home screen.
- Expected result: the home screen shows an icon labeled Jimaku. Opening it shows one screen with one button labeled 开始 (Start). Tapping it changes the label to 停止 (Stop); tapping again changes it back.
- Property: the project builds into an installable app, and the screen reflects the state held by `CaptionSession` in JimakuCore.

## Evidence

- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0: icon present, button shows 开始, one tap shows 停止, a second tap shows 开始 again. Simulator only.
- Physical device: not run.

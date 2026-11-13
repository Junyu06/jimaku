---
area: window
status: simulated
---

# Touching the caption window shows only close and return

- Input: on a device, start a session, switch to another app, and tap the floating caption window.
- Expected result: a close button and a return-to-app button appear over the window and fade again. No skip buttons, no play or stop button, no LIVE badge, and no progress bar. Captions go on updating. The close button ends the session; the return button brings the app forward.
- Property: the caption window offers only what makes sense for captions.

## Evidence

- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0: as the window appeared, the system showed the close and return buttons only. Before this change the same moment showed skip back, stop, skip forward, a LIVE badge, and a progress bar; with `requiresLinearPlayback` alone they were all still there. The two buttons were not pressed. Simulator only.
- Physical iPad: not run.
- Physical iPhone: not run.

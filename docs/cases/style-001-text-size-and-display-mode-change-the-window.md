---
area: style
status: simulated
---

# Text size and display mode change the caption window

- Input: change 字号 (text size) between 小, 中, 大 and 显示 (display) between 原文和中文 and 只显示中文, before and during a session. Close and reopen the app.
- Expected result: the caption window changes at once: larger or smaller text with fewer or more characters on a line, and with 只显示中文 only the Chinese row. The choices are still set after reopening the app.
- Property: caption appearance follows the user's settings immediately and is remembered.

## Evidence

- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0: choosing 大 during a session enlarged the text in the floating window; after reopening the app 大 was still selected; choosing 只显示中文 left only the Chinese line in the preview. 小 was not exercised. Simulator only.
- 2026-11-12, same simulator, after captions moved to fixed lines: 大 during a session gave eleven Chinese characters on a line instead of twelve, and both rows still fit the window. 小 and 只显示中文 were not exercised again. Simulator only.
- The three sizes were made smaller after these runs (twenty, fifteen, or twelve Chinese characters to a line).
- Physical iPad: not run.
- Physical iPhone: not run.

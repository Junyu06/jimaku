---
area: language
status: simulated
---

# The languages cannot be changed while a session runs

- Input: start a session, open 说话的语言 (spoken language) and tap another language in it. Change 翻译引擎 (translation engine). Stop the session and open 翻译成 (translate into).
- Expected result: while the session runs both language rows are dimmed; the menu of 说话的语言 opens with every language dimmed, and tapping one changes nothing. The engine changes. After stopping, 翻译成 opens with its languages no longer dimmed.
- Property: a session keeps the pair it started with.

## Evidence

- 2026-11-23, iPad mini (A17 Pro) simulator, iOS 27.0: each step went as expected: the menu of 说话的语言 opened with all ten languages dimmed, a tap on 韩语 left 中文 chosen, the engine was changed, and after stopping the menu of 翻译成 opened with its languages not dimmed. The menu of 翻译成 during the session was not opened.
- Physical iPad: not run.
- Physical iPhone: not run.

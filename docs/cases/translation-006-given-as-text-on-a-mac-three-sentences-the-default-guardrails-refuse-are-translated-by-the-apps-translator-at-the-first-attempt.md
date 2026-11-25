---
area: translation
status: simulated
---

# Given as text on a Mac three sentences the default guardrails refuse are translated by the app's translator at the first attempt

- Fixture: three Mandarin sentences written for this case: "战争里死了很多平民，包括小孩。" (many civilians died in the war, children among them), "他喝醉了以后打了他的老婆。" (he hit his wife after getting drunk), "这个游戏里你要开枪打死所有的僵尸。" (in this game you shoot all the zombies dead). The app's translator source files and JimakuCore compiled into a command-line program on a Mac, with Simplified Chinese as the spoken language and English as the target.
- Input: in one run, hand each sentence once, as text, first to the app's translator class given `SystemLanguageModel.default`, then to the translator that `AppleIntelligenceSource.prepare` returns.
- Expected result: each of the three calls with the default model throws a refusal, and each of the three calls to the prepared translator returns an English sentence that says what the Mandarin one says.
- Property: prepared as the app prepares it, the on-device model translates sentences that its default guardrails refuse in the same run.

## Evidence

- 2026-11-23, one Mac (macOS 27.2), one run: with the default model each of the three calls threw (what it threw is translation-007). The translator returned by `AppleIntelligenceSource.prepare` answered "Many civilians died in the war, including children.", "He hit his wife after getting drunk.", and "In this game, you have to shoot and kill all the zombies." Not the app, not speech, and not a device: recognition and the cutting of speech into captions are not part of it.
- On a device this has no case yet. A clip that was not made for it cannot be its fixture: whether it contains a sentence the default guardrails refuse is not known beforehand, and a refused sentence that is tried again may go through.
- Physical iPad: not run.
- Physical iPhone: not run.

---
area: translation
status: simulated
---

# An engine that cannot translate the languages in use is greyed out with the reason

- Input: in the settings, choose 印地语 (Hindi) as 说话的语言 (spoken language), then open 翻译引擎 (translation engine). On a device that cannot run Apple Intelligence, open 翻译引擎 with any languages.
- Expected result: both engines are listed. With Hindi, Apple Intelligence is grey, reads "Apple Intelligence（不支持印地语）", and tapping it changes nothing. On a device that cannot run the model it is grey with "这台设备不支持" whatever the languages.
- Property: an engine that cannot be used stays in the list and says why.

## Evidence

- 2026-11-23, iPad mini (A17 Pro) simulator, iOS 27.0, where the model asked is the host Mac's: with Hindi spoken and English as the target, the list showed 语言包 with its check mark and a grey "Apple Intelligence（不支持印地语）"; after tapping the grey line the engine was still 语言包. Simulator only.
- A device that cannot run Apple Intelligence: not run.
- Physical iPad: not run.
- Physical iPhone: not run.

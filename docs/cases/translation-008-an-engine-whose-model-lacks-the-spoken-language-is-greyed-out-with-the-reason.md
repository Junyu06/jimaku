---
area: translation
status: simulated
---

# An engine whose model lacks the spoken language is greyed out with the reason

- Fixture: the app with its interface in Chinese, on a device whose on-device model does not work in Hindi; 说话的语言 (spoken language) 日语, 翻译成 (translate into) 英语, and 翻译引擎 (translation engine) set to 语言包 by choosing it from the list.
- Input: choose 印地语 (Hindi) as 说话的语言, open 翻译引擎, tap the line for Apple Intelligence, close the list, and choose 日语 as 说话的语言 again.
- Expected result: with Hindi, the list shows 语言包 with the check mark and a grey line "Apple Intelligence（不支持印地语）". After the tap and with 日语 again, 翻译引擎 still reads 语言包.
- Property: an engine that cannot translate the spoken language stays in the list, says why, and cannot be chosen.

## Evidence

- 2026-11-23, iPad mini (A17 Pro) simulator, iOS 27.0, where the model asked is the host Mac's and every language pack is reported as installed: 翻译引擎 read Apple Intelligence at first and was set to 语言包 from the list. With Hindi, the list showed 语言包 checked and the grey line above. After tapping the grey line and choosing 日语 again, 翻译引擎 read 语言包. Simulator only.
- Physical iPad: not run.
- Physical iPhone: not run.

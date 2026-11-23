---
area: translation
status: simulated
---

# An engine whose model lacks the spoken language is greyed out with the reason

- Fixture: the app with its interface in Chinese, where the system has answered and the on-device model works in Japanese and English and not in Hindi; 说话的语言 (spoken language) 日语, 翻译成 (translate into) 英语, and 翻译引擎 (translation engine) set to 语言包 by choosing it from the list while both engines can be chosen.
- Input: choose 印地语 (Hindi) as 说话的语言, open 翻译引擎, tap the line for Apple Intelligence, close the list, choose 日语 as 说话的语言 again, and open 翻译引擎.
- Expected result: with Hindi, the list shows 语言包 with the check mark and a grey line "Apple Intelligence（不支持印地语）". With 日语 again, the list shows both engines as lines that can be chosen, with the check mark on 语言包.
- Property: an engine that cannot translate the spoken language stays in the list, says why, and cannot be chosen.

## Evidence

- 2026-11-23, iPad mini (A17 Pro) simulator, iOS 27.0, interface in Chinese, where the model asked is the host Mac's and every language pack is reported as installed. With 日语 into 英语 the list showed 语言包 and Apple Intelligence, both as lines that can be chosen, the check mark on Apple Intelligence; 语言包 was then chosen. With Hindi, the list showed 语言包 checked and the grey line above. The grey line was tapped, the list closed, and 日语 chosen again: 翻译引擎 read 语言包. After the app was closed and opened again, the list showed both engines as lines that can be chosen, with the check mark on 语言包. Simulator only.
- Physical iPad: not run.
- Physical iPhone: not run.

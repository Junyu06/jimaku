---
area: interface
status: simulated
---

# A language chosen for the app after the first launch does not change the pair of languages

- Input: on a device whose first preferred language is Simplified Chinese and that can caption English into Simplified Chinese, install the app, open it without touching the language rows, and close it. In the system's Settings choose English for Jimaku, and open the app again.
- Expected result: both times the first two rows of the settings show English as the source and Simplified Chinese as the target; the second time their names are in English.
- Property: the language of the interface and the languages of the captions are two choices; the pair worked out at the first launch is kept.

## Evidence

- 2026-11-25, iPad mini (A17 Pro) simulator, iOS 27.0, with the app and its settings removed first: launched with `-AppleLanguages "(zh-Hans)"`, the rows read 英语 and 简体中文; launched again with `-AppleLanguages "(en)"`, they read English and Chinese, Simplified. Removed again and launched with `-AppleLanguages "(en)"` first, they read Japanese and English, which is what the second launch would have shown had the pair been worked out again. A simulation: the launch argument stands in for the language chosen in the system's Settings.
- Physical device: not run.

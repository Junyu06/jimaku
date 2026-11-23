---
area: language
status: simulated
---

# A spoken language stored by the two-language version keeps translating into Simplified Chinese

- Input: on a device whose app was the version with two spoken languages, with 日语 (Japanese) chosen there, install this version over it and open it.
- Expected result: the spoken language is 日语 and the target 简体中文, whatever the device's own language.
- Property: an update does not change what someone who had chosen a spoken language was getting.

## Evidence

- 2026-11-23, iPad mini (A17 Pro) simulator, iOS 27.0, where the earlier version had been run with Japanese chosen: this version opened with 日语 and 简体中文.
- Physical iPad: not run.
- Physical iPhone: not run.
- Someone who never changed the spoken language in the earlier version has nothing stored and gets the defaults for a new install; see `docs/decisions/2026-11-23-translate-into-the-devices-language-by-default-and-into-simplified-chinese-after-an-update.md`. That case is covered by tests of JimakuCore and was not run.

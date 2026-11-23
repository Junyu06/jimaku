---
area: language
status: simulated
---

# Choosing the language of the other side swaps the two

- Input: with 日语 (Japanese) as the spoken language and 简体中文 as the target, choose 中文 as the spoken language. Then choose 英语 as the target, then 繁体中文, then 英语 again.
- Expected result: after choosing 中文 as spoken the target is 日语. After 英语 the pair is 中文 into 英语. After 繁体中文 it is 英语 into 繁体中文. After 英语 again it is 中文 into 英语.
- Property: no choice leaves the same language on both sides, and Traditional Chinese, which is only written, swaps in as spoken Chinese.

## Evidence

- 2026-11-23, iPad mini (A17 Pro) simulator, iOS 27.0, where every language is reported as ready: each step gave the pair above. The first two steps were run on an earlier build of this change and the last two on the present one; the rule those first two steps use did not change in between. The spoken list showed ten languages and the target list eleven.
- Physical iPad: not run.
- Physical iPhone: not run.

date: 2026-11-23
status: accepted
supersedes: none

# Swap the two languages when one side is chosen as the other

Neither list in the settings is narrowed by the other side. Choosing as the spoken language the language captions are translated into makes the old spoken language the target; choosing as the target the spoken language makes the old target the spoken one. Simplified and Traditional Chinese count as one language for this. Traditional Chinese is only translated into, so when it swaps to the spoken side it becomes Mandarin. When a swap would still leave Chinese on both sides, the first other language in the list takes the side that was not chosen.

Why: the two forms of one language are not translated into each other, so a pair with the same language on both sides cannot run. A swap keeps what the user just chose and puts the other language somewhere useful.

Rejected: narrowing the spoken languages to those that fit the chosen target. With Simplified Chinese as the target, Chinese was then not among the spoken languages, and the way to caption Chinese speech was to change the target first. This was built and seen in a simulator before it was replaced.

Status of evidence: covered by tests of JimakuCore, and seen in an iPad simulator; see `docs/cases/language-003-choosing-the-language-of-the-other-side-swaps-the-two.md`.

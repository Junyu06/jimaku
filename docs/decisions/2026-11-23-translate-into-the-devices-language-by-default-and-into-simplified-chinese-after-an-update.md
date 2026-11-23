date: 2026-11-23
status: accepted
supersedes: none

# Translate into the device's language by default, and into Simplified Chinese after an update

With no pair stored, captions are translated into the first of the device's preferred languages that the app's list has, or into English when it has none of them. The spoken language is then English, or Japanese when the target is English.

The version before this one had two spoken languages and always translated into Simplified Chinese. It stored the spoken language only when the user changed it. Where that stored value is found, the pair is that spoken language into Simplified Chinese.

Why: a reader wants captions in a language they read, and the device's own language is the best guess at it. Someone who chose a spoken language in the earlier version was reading Simplified Chinese captions and should go on getting them.

Cost accepted: someone who used the earlier version without ever changing the spoken language has nothing stored, and is treated as new. On a device in English that changes their captions from English into Simplified Chinese to Japanese into English until they choose again.

Status of evidence: covered by tests of JimakuCore. In an iPad simulator, a choice of Japanese stored by the earlier version came back as Japanese into Simplified Chinese; see `docs/cases/language-004-a-spoken-language-stored-by-the-two-language-version-keeps-translating-into-simplified-chinese.md`.

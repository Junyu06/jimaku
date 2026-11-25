date: 2026-11-25
status: accepted
supersedes: none

# Keep the interface's Chinese text in the source and its English in string catalogs

The source keeps the Chinese text, which is also the key. Each text has its English in a string catalog: `JimakuApp/Localizable.xcstrings`, `JimakuBroadcast/Localizable.xcstrings` for what the extension says when it ends a broadcast, and `JimakuApp/InfoPlist.xcstrings` for the reason given with the speech-recognition permission. Text handed to SwiftUI as a literal is looked up by SwiftUI; text built as a string asks for its translation. See `docs/conventions/write-interface-text-in-chinese-in-the-source-and-its-english-in-the-string-catalog.md`.

Why: the owner reads and corrects the Chinese; keeping it in the code keeps his words where he looks, and a text and its key cannot drift apart when they are the same.

Rejected: English as the source text with Chinese in the catalog. The words the owner corrects would then sit in a second file, under keys in another language.

A test reads the source and the catalogs and fails when a Chinese text has no English: `InterfaceStringsTests` in JimakuCore. Which language shows is not decided here: `docs/decisions/2026-11-25-leave-the-choice-of-the-interfaces-language-to-the-systems-settings.md`.

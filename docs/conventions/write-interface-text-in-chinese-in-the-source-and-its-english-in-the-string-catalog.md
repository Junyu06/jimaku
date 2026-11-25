# Write interface text in Chinese in the source and its English in the string catalog

Text the user reads is written in Simplified Chinese in the Swift source. The same text is the key of an entry in the target's `Localizable.xcstrings`, which carries its English.

- A literal handed to SwiftUI (`Text("开始")`, `Button("下载")`, a section or picker title) is looked up by SwiftUI. A function that returns such text returns `LocalizedStringKey`, not `String`.
- Text built as a `String` (a notice, an error description, what the caption window shows, an accessibility label on a UIKit view) is written `String(localized: "…")`. A `String` put into it with `\(…)` is `%@` in the key; a number would be `%lld`.
- Adding or changing a text means adding or changing its catalog entry in the same commit, with both languages filled in. Where English orders the values differently, its text uses `%1$@`, `%2$@`.
- A text that does not read as its own key (the caption in the preview) has a named key, and as `defaultValue:` what the Chinese interface shows for it, which for the preview's original line is an English sentence.
- Two texts shown one after the other are joined by a text of their own (`String(localized: "\(first)\(second)")`, the key `%@%@`), not with `+`: English puts a space between them, and another language may turn them round.
- The broadcast extension has a catalog of its own; it cannot read the app's.
- `swift test` in JimakuCore reads the source and the catalogs (`InterfaceStringsTests`). It fails when a Chinese literal has no English, when the two take different numbers of values, when a named key is missing, and, in the files on its list, when a plain string is not looked up. A new file that holds only plain strings is added to that list. It does not see everything: a literal over several lines, a file in a folder below the target's, the values of a text with no Chinese in it (`%@%@`), and a plain string in a file that also holds SwiftUI text (`StartView.swift`) pass unseen, so those are checked by eye and by running the app in English.

# The recognizer writes Mandarin with a space before each comma

Measured on macOS 27.2 on 2026-11-23, with `SpeechTranscriber` for `zh-CN`, progressive transcription, fed 18 seconds of synthesized Mandarin: every full-width comma in both volatile and final results came with a space before it ("超市 ，买了"). Shown as it comes, the original row has a gap before every comma. No full stop came inside a result in that sample; a full stop arrived as a final result of its own at the end.

What to do: pass what the recognizer reports through `CaptionLanguage.tidying`, as `SystemSpeechRecognizer` does. For Chinese it removes a run of plain spaces that stands before a wide mark closing a phrase (`CaptionText.closingUpMarks`); for every other language it changes nothing.

Do not apply it to other languages. Removing a space changes the width of the text, and where speech is cut depends on width: in Japanese, eleven wide characters and two spaces before a comma are 24 columns and the speech is cut at the comma, and without the spaces they are 22 and it is not. The rules for Japanese and English were tuned on what the recognizer writes, spaces included.

Whether an iPad writes Mandarin the same way has not been seen.

date: 2026-11-12
status: superseded in part by 2026-11-12-turn-the-page-when-the-translation-row-is-full.md: the translation row no longer rolls a sentence off at a time, it fills like a page and starts a new one. Each sentence on a line of its own stands, and so do the rules for the original row.
supersedes: laying one piece after another on the same line, and the rule that a row never rolls back, in 2026-11-12-lay-captions-out-in-fixed-lines-that-roll-up.md. Fixed lines, rolling by whole lines, and text that does not move sideways once shown stay as they are.

# Show each sentence on a line of its own

On both rows, every kept piece of speech and every translation starts on a new line. A row rolls a whole piece off at a time: it does not show the end of a piece whose beginning has left. The only exception is the newest piece when it alone is longer than the row.

- The translation row, with two lines, shows the last two short translations, or one that needs both lines.
- The original row, with one line, shows the sentence being said, dimmer while it may change. It stays after it is said until the next one begins.
- The waiting mark stays at the end of the last translation and never pushes a translation off the row. With no translation on the row yet, it stands alone.
- A translation longer than the row is shown from its beginning. After 2.5 seconds the row moves on to the rest, a page at a time, the last page ending with the translation's last line. If the next translation arrives first, it takes the row and the rest is not shown.
- When the speech in progress is withdrawn or gets shorter, a row comes back to the sentence it had made room for.
- Speech longer than the original row shows its end, while it is being said and after.

Why: with pieces flowing one after another, a row often began with the tail of a sentence, a word or two and a full stop, whose beginning had rolled away. A reader had to work out that it belonged to nothing they could still see. On a physical iPad the owner asked for one caption per thing said, the way subtitles made for a video show them.

Rejected: showing only one translation at a time. A short answer would replace the question it answers before both could be read; two lines hold both.

Rejected: showing only the end of a translation that is too long for the row, as the rows did before. In one run over the recording used for the measurements, 2 translations of 60 were a few characters too long for two lines; showing the end would have dropped the whole first line of each.

Rejected: cutting speech short enough that its translation always fits. The Chinese can come out longer than the Japanese it translates, so no limit on the speech guarantees it.

Cost accepted:

- Two short lines use less of the row than flowing text did, so less is on screen at once.
- When a translation needs both lines, the one before it leaves at that moment, however recently it appeared.
- The first lines of a long translation stay for a fixed 2.5 seconds, whatever their length and however fast the reader is, and its last lines are lost if the next translation arrives within that time.
- After a long sentence is said, the original row holds only its last line.

Status of evidence: the rows are covered by unit tests; the timer that turns the page is in the app's session controller and is not. Seen in an iPad simulator with scripted English at medium size, and on a Mac in the rows computed for a 145-second recording of Japanese conversation. Not yet run on a physical device.

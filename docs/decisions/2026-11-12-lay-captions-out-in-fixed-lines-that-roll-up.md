date: 2026-11-12
status: superseded in part by 2026-11-12-translate-a-sentence-only-when-it-has-ended.md. The fixed lines that roll up still stand. The translation row no longer shows a provisional translation; it shows a waiting mark instead. Superseded in part by 2026-11-12-show-each-sentence-on-a-line-of-its-own.md as well: pieces no longer follow one another on a line, and a row comes back when speech in progress is withdrawn. Superseded in part by 2026-11-12-let-the-reader-choose-how-many-lines-the-translation-has.md: the translation row has two to four lines as the reader chooses, and the frame grows taller than 400 pixels for them. Superseded in part by 2026-11-12-make-the-caption-text-smaller-and-give-it-more-room.md and 2026-11-12-set-the-small-and-medium-text-a-little-larger.md: the columns by text size. Superseded in part by 2026-11-12-turn-the-page-when-the-translation-row-is-full.md: the translation row does not roll, it turns a page.
supersedes: the sentence "Both caption rows run on like a ticker and show their end" in 2026-11-12-translate-speech-while-it-is-still-in-progress.md

# Lay captions out in fixed lines that roll up

Each caption row has a fixed number of lines of a fixed width. Text is added at the end. A line that is full never changes; when a new line is needed and the row is full, the oldest line leaves and the others move up by one. The text size follows from how many columns a line holds, and lines are broken by the widths of the font they are drawn in, measured at the size they are drawn, so text is not shrunk or re-centered as it arrives. The exceptions are under "Cost accepted".

Text that will not change is drawn bright. Text that still may (the speech in progress, and its provisional translation) is drawn dimmer after it. Of the provisional translation only one line's worth of its beginning is shown.

Why: the version before this one showed the end of a running string, cut to the row's width. Every new character moved every character on the row, and the text was wrapped and shrunk to fit again each time. On a physical iPad the owner found it hard to read. A reader's eye cannot hold its place in text that slides sideways several times a second; when a whole line moves up by one, it can. Broadcast captions for live programs roll up for the same reason.

Why the provisional translation is cut short: it is a preview, and its end is the part most likely to change when more is said, most of all from Japanese, where the verb comes last. Shown in full it could fill the row with text that is about to be rewritten and push out the lines the reader is on.

Rejected: clearing the row when it is full and starting again from the top. The last piece translated would often be on screen for less than a second.

Rejected: one piece per line. A translated clause is often longer than a line of the floating window.

The layout by text size, for a 1200 by 400 frame: the translation gets two lines of 30, 24, or 22 columns (a wide character is two columns); the original gets one line of 52, 46, or 42 columns above it. Alone, the translation keeps its size and gets a third line at the small size. When translation cannot run, the original takes the translation's place.

Cost accepted:

- A translation that arrives after a later one is already on the row is left out of the window, because putting it in the middle would move text. It is still in the session log.
- The original row has one line, so each time it fills it starts again with a few words.
- Widths are measured for ASCII letters, digits, and marks. Other narrow characters, such as accented letters, are given a generous fixed width. If a line still comes out too wide, it is drawn slightly smaller, and that one line then moves.
- Text that arrives later is never tied to a character already shown. So a mark at the very start of a new piece can begin a line, which is otherwise avoided. A mark also begins a line when it and the character before it do not fit on one line together.
- A row can roll once for provisional text that then gets shorter. It does not roll back, except when that leaves nothing to show: then the last line returns.

Status of evidence: line breaking, rolling, and the layout are covered by unit tests. Seen in an iPad simulator with scripted Japanese at medium and large size and scripted English at large size. A line drawn smaller because it was too wide is written to the system log; in a simulator run of about 35 seconds with scripted English at large size, none was. Japanese and the other sizes were not checked this way. Not yet run on a physical device.

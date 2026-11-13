date: 2026-11-12
status: accepted
supersedes: for the translation row, a line of its own for each sentence and rolling a sentence off at a time, in 2026-11-12-show-each-sentence-on-a-line-of-its-own.md, and rolling by whole lines in 2026-11-12-lay-captions-out-in-fixed-lines-that-roll-up.md; and from the first of these, the fixed 2.5 seconds for a page and the last page that repeated lines of the one before. The original row is as it was: each sentence on a line of its own, rolling.

# Turn the page when the translation row is full

The translation row fills from the top like a page of text. A translation follows the one before it on the same line, after a gap, and runs on to the next line. When it does not fit in what is left of the page, the page is cleared and it starts the new page at the top. Nothing on a page moves while the page is up.

- The gap is as wide as a Chinese character. After a full-width mark such as "。", which has blank space of its own, it is one narrow space; between Latin letters it is two spaces. A gap is not kept where a line ends.
- A translation longer than a whole page is shown from its beginning, then the rest a page at a time, no line twice. A page stays a second and a quarter for each line the row has before it is turned.
- What follows such a translation goes on the page where it ends, and that page is shown, so its last lines are seen with what comes next.
- When several translations arrive at once, the page on which the newest begins is shown.
- The waiting mark stays at the end of the last translation if there is room on its line, and never takes a line.

Why: the owner compared the window with another caption app in which a page of text fills, stays still, and is replaced by the next, and found that easier to read than lines that move up every time someone speaks. With a row of up to five lines, rolling moves every line on it at each new sentence; a page moves nothing until it is full.

Why the translations run on: the owner wanted more of what was said in the window, and with a line for each sentence a turn of two or three characters took a whole line of thirty. Asked whether to keep the lines apart, run them together as that other app does, or run them together with a small gap, the choice was the gap: it keeps most of the room, and a reader can still tell where one thing said ends and the next begins, also when a short turn has no mark at its end.

Rejected: filling what is left of a page with the beginning of a sentence and putting the rest on the next page. A translation arrives whole, so both parts would be due at the same moment, and the first would have to be held on screen by a timer while newer speech waits.

Cost accepted:

- The last sentence on a page is cleared as soon as the next one that does not fit arrives, however recently it appeared; earlier sentences on the same page have had longer.
- A page that is turned for a sentence that would not fit leaves the rest of its last line, or more, unused.
- A question and its answer can end up on different pages.
- Two things said by different people can stand on one line, told apart only by the gap.

Status of evidence: the row and the board are covered by unit tests. In an iPad simulator with scripted Japanese at the small size with five lines, translations ran on with gaps between them, a page stayed still while it filled, and it was replaced whole when the next translation did not fit. Not run on a physical device.

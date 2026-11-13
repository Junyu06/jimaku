date: 2026-11-12
status: accepted
supersedes: for the translation row, rolling a sentence off at a time in 2026-11-12-show-each-sentence-on-a-line-of-its-own.md and rolling by whole lines in 2026-11-12-lay-captions-out-in-fixed-lines-that-roll-up.md; and from the first of these, the fixed 2.5 seconds for a page and the last page that repeated lines of the one before. Each sentence on a line of its own stays. The original row still rolls.

# Turn the page when the translation row is full

The translation row fills from the top like a page. A translation goes on the next free line. When it does not fit in the lines that are left, the page is cleared and it starts the new page at the top. Nothing on a page moves while the page is up.

- A translation longer than a whole page is shown from its beginning, then the rest a page at a time, no line twice. A page stays a second and a quarter for each line the row has before it is turned.
- What follows such a translation goes on the page where it ends, and that page is shown, so its last lines are seen with what comes next.
- When several translations arrive at once, the page on which the newest begins is shown.
- The waiting mark stays at the end of the last translation if there is room on its line, and never takes a line.

Why: the owner compared the window with another caption app in which a page of text fills, stays still, and is replaced by the next, and found that easier to read than lines that move up every time someone speaks. With a row of up to five lines, rolling moves every line on it at each new sentence; a page moves nothing until it is full.

Rejected: letting sentences run on in one paragraph, as that other app does. Starting each on its own line is what lets a reader tell one speaker's turn from the next, and the owner asked for it earlier.

Rejected: filling the lines that are left with the beginning of a sentence and putting the rest on the next page. A translation arrives whole, so both parts would be due at the same moment, and the first would have to be held on screen by a timer while newer speech waits.

Cost accepted:

- The last sentence on a page is cleared as soon as the next one arrives, however recently it appeared; earlier sentences on the same page have had longer. With two lines this happens at every second sentence.
- A page that is turned for a sentence that would have fit on a fuller row leaves free lines unused.
- A question and its answer can end up on different pages.

Status of evidence: the row and the board are covered by unit tests. In an iPad simulator with scripted Japanese at the small size with five lines, pages filled from the top, stayed still while they filled, and were replaced whole. Not run on a physical device.

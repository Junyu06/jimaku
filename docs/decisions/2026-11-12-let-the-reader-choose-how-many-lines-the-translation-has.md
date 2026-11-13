date: 2026-11-12
status: superseded in part by 2026-11-12-allow-a-fifth-line-of-translation.md: the choice goes up to five. The frame heights named below were for the text sizes of the time; see 2026-11-12-make-the-caption-text-smaller-and-give-it-more-room.md.
supersedes: the number of lines of the translation row in 2026-11-12-lay-captions-out-in-fixed-lines-that-roll-up.md: "two lines", and "a third line at the small size" when the translation is alone. The 1200 by 400 frame there is now the smallest frame.

# Let the reader choose how many lines the translation has

The settings have a choice of two, three, or four lines for the main row, two unless changed. It applies at every text size and in both display modes, and to the original when it stands in for a translation that cannot run. The original row above a translation keeps its one line.

The text keeps its size. The frame the captions are drawn in stays 1200 pixels wide and is at least 400 high; a layout whose lines need more gets a frame as much taller as they need, and the floating window takes the frame's shape. With the original row shown, three lines at the small size need 404 pixels and four need 494; three lines at the medium size need 478.

Why: the owner, reading at the small size on an iPad, asked for three or four lines of translation under the one line of original; the medium and large sizes were too large for that reader, and at the small size two lines were too few. Each sentence starts on a new line, so with two lines a caption in quick conversation is pushed out by the next one or two. More lines keep it on the row longer, and fewer long translations need a second page.

Rejected: tying the number of lines to the text size, as the third line at the small size was. How much a reader wants to see at once and how large the text should be are separate choices.

Rejected: fitting more lines into the 400-pixel frame by drawing the text smaller. The text size is the reader's choice, and lines are broken by the widths measured at that size.

Cost accepted:

- A taller window covers more of what is being watched. The system decides how large the window is on screen.
- With the translation alone at the small size, the third line no longer comes by itself; it is chosen like any other.
- Changing the number of lines during a session changes the window's shape at once.

Status of evidence: the layout and the frame heights are covered by unit tests. In an iPad simulator with scripted speech, four lines at the small size gave a taller floating window with one line of original and four of translation, and choosing two during the session brought the window back to its earlier shape. Not run on a physical device.

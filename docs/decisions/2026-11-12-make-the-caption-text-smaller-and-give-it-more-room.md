date: 2026-11-12
status: accepted
supersedes: 2026-11-12-make-the-caption-text-smaller-at-every-size.md, which had gone to 40, 30, and 24 columns. With it, the columns by text size in 2026-11-12-lay-captions-out-in-fixed-lines-that-roll-up.md.

# Make the caption text smaller and give it more room

A line of translation now holds 54, 46, or 40 columns at the small, medium, and large size. It held 30, 24, or 22 at first and 40, 30, or 24 after a first step. A wide character is two columns, so that is twenty-seven, twenty-three, or twenty Chinese characters. The original line above it holds 76, 66, or 60 columns.

The text also gets more room. The space left clear at each edge of the 1200-pixel frame goes from 24 pixels to 40, and lines are set at 1.4 times the text size instead of 1.2.

Why: the owner, on an iPad, found the medium and large sizes too large to use and the small one still much larger than the text of another caption app. That first step was tried on the iPad the same day; the owner reported every size as still two or three steps too large, the smallest looking like a medium or large one, and the window as crowded, with too little room around the text. A second step to 60, 50, and 40 columns was tried there as well: the large size was left as it was, and the small and medium ones were reported as a little too small, which gave the present 54 and 46. Smaller text puts more of what was said into the same window.

Rejected: a fourth, smaller size next to the old three. All three were larger than the reader could use.

Cost accepted:

- A reader who had chosen a size sees much smaller text after this change, since the setting is stored by name.
- At the small size the original line is drawn at 29 pixels in a frame 1200 wide, which is small in a window that has been pinched down.
- With smaller text more lines fit the smallest frame: at the small size two to four lines of translation all use the 1200 by 400 frame, and five need 38 pixels more.

Status of evidence: the layout and the frame's measures are covered by unit tests. The room around the text and the large size were seen on a physical iPad by the owner; the present small and medium sizes were not.

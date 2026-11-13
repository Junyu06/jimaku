date: 2026-11-12
status: accepted
supersedes: the columns by text size in 2026-11-12-lay-captions-out-in-fixed-lines-that-roll-up.md: "30, 24, or 22 columns" for the translation and "52, 46, or 42" for the original.

# Make the caption text smaller and give it more room

A line of translation now holds 60, 50, or 40 columns at the small, medium, and large size, where it held 30, 24, or 22. A wide character is two columns, so that is thirty, twenty-five, or twenty Chinese characters. The original line above it holds 84, 72, or 60 columns.

The text also gets more room. The space left clear at each edge of the 1200-pixel frame goes from 24 pixels to 40, and lines are set at 1.4 times the text size instead of 1.2.

Why: the owner, on an iPad, found the medium and large sizes too large to use and the small one still much larger than the text of another caption app. A first step to 40, 30, and 24 columns was tried on the iPad the same day; the owner reported every size as still two or three steps too large, the smallest looking like a medium or large one, and the window as crowded, with too little room around the text. Smaller text puts more of what was said into the same window.

Rejected: a fourth, smaller size next to the old three. All three were larger than the reader could use.

Cost accepted:

- A reader who had chosen a size sees much smaller text after this change, since the setting is stored by name.
- At the small size the original line is drawn at 26 pixels in a frame 1200 wide, which is small in a window that has been pinched down.
- With smaller text more lines fit the smallest frame: at the small size two to four lines of translation all use the 1200 by 400 frame, and five need six pixels more.

Status of evidence: the layout and the frame's measures are covered by unit tests. Not run on a physical device at these sizes.

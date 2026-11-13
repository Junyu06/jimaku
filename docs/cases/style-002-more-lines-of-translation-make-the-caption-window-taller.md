---
area: style
status: simulated
---

# More lines of translation make the caption window taller

- Input: on a device, choose 中文行数 (lines of Chinese) 2 to 5, at each text size, before and during a session with continuous speech. Close and reopen the app.
- Expected result: the floating window shows that many lines of translation under the one line of original, with the text the same size as before; the window is taller once the lines no longer fit its lowest shape (at the small size only with five lines, and then by little). During a session the window changes shape at once and goes on showing captions. The choice is still set after reopening the app.
- Property: how many captions stay in view is the reader's choice, separate from how large the text is.

## Evidence

- 2026-11-12, iPad mini (A17 Pro) simulator, iOS 27.0, scripted Japanese, small text, 4 lines set before launch: the preview and the floating window were taller than before and showed one line of original above four lines of translation, each sentence on its own line. Choosing 2 during the session brought the floating window back to its earlier shape with two lines of translation. 3 lines, the other text sizes, and reopening the app were not exercised. Simulator only.
- The text sizes were made smaller and a fifth line was added after that run; the heights changed with them.
- 2026-11-12, physical iPad: the owner used the choice of two to five lines during sessions over a short-video app, at text sizes of 40, 30, and 24 columns and then 60, 50, and 40, and reported the lines as fine, five being the choice they would usually keep. Reopening the app and each size with each number of lines were not reported. No screenshot kept.
- Physical iPad, the present small and medium sizes: not run.
- Physical iPhone: not run.

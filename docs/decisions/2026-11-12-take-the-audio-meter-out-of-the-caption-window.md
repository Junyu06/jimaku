date: 2026-11-12
status: accepted
supersedes: the frame heights named in 2026-11-12-allow-a-fifth-line-of-translation.md, 2026-11-12-make-the-caption-text-smaller-and-give-it-more-room.md, 2026-11-12-make-the-caption-text-smaller-at-every-size.md, and 2026-11-12-let-the-reader-choose-how-many-lines-the-translation-has.md, which included 20 pixels for the meter. No decision recorded the meter itself; it came with the first caption window.

# Take the audio meter out of the caption window

The caption window no longer draws a level meter along its bottom edge, and no space is set aside for one. The frame holds the rows and the room around them and nothing else. A frame that had to be taller than 400 pixels is 20 pixels lower than before: with the original row and five lines of translation it is now 418 pixels high at the small size, 474 at the medium size, and 528 at the large size, for a width of 1200.

Why: the meter was there to show that the audio of another app was reaching this one, while that was still in doubt. It has been seen to arrive on a physical iPad in every session since, and the owner asked for the bar to go: it moves all the time at the edge of the text and takes room.

What still shows that audio is arriving: the captions themselves, and before there are any, the window's one-line notices, which tell "waiting for the broadcast" from "no sound for now" from "listening".

Cost accepted: with captions on screen, a stall in the audio no longer shows in the window; the captions stop coming. The app's own screen still says so.

Status of evidence: the frame's measures are covered by unit tests. Not run on a physical device.

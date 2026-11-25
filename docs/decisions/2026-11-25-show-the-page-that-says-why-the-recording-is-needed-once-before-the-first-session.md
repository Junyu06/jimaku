date: 2026-11-25
status: accepted
supersedes: none

# Show the page that says why the recording is needed once before the first session

The first tap on Start, when the page has not been read before, does not start a session. It brings up the page that says why the recording is needed (see `docs/decisions/2026-11-25-say-what-the-recording-is-for-under-the-wide-button-and-why-it-is-needed-behind-a-question-mark.md`), with the button 继续 (Continue). That button starts the session once the page has left the screen. A session started later starts at once.

Why: the system's sheet comes up by itself right after Start (see `docs/decisions/2026-11-23-press-the-systems-broadcast-control-in-code-when-the-caption-window-has-appeared.md`), and without the page that sheet would be the first the user hears of a recording. The owner asked whether the app should not tell a user how it is used.

Only the page's button counts as having read it: a page swiped away starts nothing and comes again at the next tap on Start. The button counts wherever the page was opened from: a user who opened it from the help row or the question mark and closed it with its button is not shown it again at Start. That it was read is kept with the app's settings on the device.

The session is started when the page is gone, not on the tap: the caption window and the system's sheet come up over the start page. If the user has left the app by then, or a session is already there, nothing is started; the next tap on Start starts at once.

Rejected: showing the page at every start, or until a broadcast has once run. A user who has read it once has no use for it in the way.

Status of evidence: when the page is due, and when its going starts a session, are covered by tests of JimakuCore (`RecordingExplanation`). The first start was looked at in an iPad simulator; see `docs/cases/audio-009-the-first-tap-on-start-shows-why-the-recording-is-needed-and-the-session-starts-when-that-page-is-closed-with-its-button.md`. Leaving the app while the page is going was not tried anywhere. Nothing of this has run on a device, where the system's sheet has to follow the page's button.

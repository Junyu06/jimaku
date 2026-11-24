date: 2026-11-24
status: accepted
supersedes: in 2026-11-23-lay-the-systems-broadcast-control-over-one-wide-button-while-no-broadcast-runs.md, that the caption window says the recording is off only while it has nothing else to say

# Say that the recording is off in place of captions already shown while no broadcast runs

While a session runs and no screen broadcast does, the caption window reads 录屏未打开 (the recording is not on), whether or not it has captions to show, and before anything it would say about a translation it is waiting for. When a broadcast runs again the captions are back, as they then are: a page that was due to turn has turned meanwhile. Through a silence during a broadcast the captions stay up, as before. When recognition has failed the window does not say this: opening the recording would bring no more captions, and the page says what went wrong.

Why: the window said what the session was waiting for only while it had no caption at all, and a session's rows keep the captions they have shown. So when a broadcast ended in the middle of a session, because the user stopped it from the system's controls or the system ended the extension, the window kept its last captions and nothing said that no more would come. The user is then in another app, looking at the window and not at the start page, which does offer the recording. Found by reading the code during a review of the page's texts, and seen in an iPad simulator.

Rejected: leaving the captions up and adding the notice to them. The window has fixed rows and no place for a line that is not a caption.

Rejected: ending the session when the broadcast ends. The user may start the broadcast again; and what should happen to the session when the user comes back to the app is not decided.

This sets aside, for this one state, the rule that caption text shown as settled does not change: the text is not changed, it is covered.

Status of evidence: the rule is covered by tests of JimakuCore (`CaptionPlaceholder.replacingCaptions` and `CaptionPlaceholder.choose`). In an iPad simulator the window read 录屏未打开 while the session's log held captions; see `docs/cases/audio-007-with-captions-already-shown-and-no-broadcast-the-caption-window-says-the-recording-is-off.md`. A broadcast ended in the middle of a session has not been tried on a device; see `docs/cases/audio-008-stopping-the-broadcast-in-the-middle-of-a-session-makes-the-caption-window-say-the-recording-is-off.md`. There the app learns of it at once when the extension is told to finish, and otherwise when the extension has shown no sign of life for five seconds.

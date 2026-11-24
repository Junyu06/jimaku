date: 2026-11-23
status: superseded in part by 2026-11-24-say-that-the-recording-is-off-in-place-of-captions-already-shown-while-no-broadcast-runs.md: when the caption window says the recording is off. The rest stands.
supersedes: none

# Lay the system's broadcast control over one wide button while no broadcast runs

A session hears other apps only through a screen broadcast, and only the user can start one, in a sheet of the system's that only the system's own control brings up. Once a session's caption window is up and no broadcast runs, the start page shows one filled button as wide as the page, 打开录屏 (open the recording). Under it a label of a few words says that only the sound is used and the picture is not kept. Stop is drawn as a quieter button from the tap on Start until a broadcast runs. The caption window, while it has nothing else to say, reads 录屏未打开 (the recording is not on).

Why: the owner, after using the app on an iPad, said that a session with no recording should say so plainly with a button nobody can miss, and that instructions are forgotten. Before this the page showed a line of text beside the system's control, a round glyph 44 points across; the line told the user to tap the round button on the right, choose Jimaku, and start the broadcast. The owner read the line as not something a person would say, and the control as too small to be found.

How: the system's control is laid over the whole of a button the page draws, at an opacity of 0.02, so that its glyph does not show and a tap on the page's button is meant to land on the control. The page's button takes no touches and is hidden from assistive technology; the control's own button carries the name. The control holds one button, which the app finds among its subviews and gives the control's whole size at each layout; see `docs/pitfalls/a-broadcast-picker-made-with-no-size-keeps-a-button-of-no-size.md`. This leans on how the control is built inside: on a system that builds it without such a button, the wide button would be drawn and would do nothing.

The button is not shown before the caption window is up: the app asks for the same sheet at that moment, and a tap a moment earlier would ask twice. See `docs/decisions/2026-11-23-press-the-systems-broadcast-control-in-code-when-the-caption-window-has-appeared.md`.

The texts are labels, not sentences. A first version put a sentence of some forty characters under the button, explaining why the recording is needed, that the picture is not kept, and which button the system would ask for; the owner, seeing it on an iPad, said that is not what the text of an interface looks like. What the button is for is left to the button and to the system's sheet.

The label says the picture is not kept because the broadcast extension writes only the audio the system hands it and drops every other buffer; see `JimakuBroadcast/SampleHandler.swift`.

Rejected: a button of the app's own that sends the control a tap in code. If a system stops honoring that, the button does nothing and the app has no way left to start a broadcast.

Rejected: keeping the system's glyph and writing better instructions beside it. The owner's point was that the control cannot be found and that instructions are forgotten.

Not decided here: what happens to the broadcast and the session when the user comes back to the app. Closing the caption window still ends the session, and the extension ends the broadcast when it next sees that no session wants audio.

Status of evidence: which state the page shows is covered by tests of JimakuCore (`RecordingGuide`). The page was looked at in an iPad simulator, where there is no screen broadcast; see `docs/cases/audio-004-a-session-with-no-broadcast-shows-the-wide-button-and-a-label-saying-only-sound-is-used.md`. There, with a build that logged it, taps 15 points from either end of the button reached the control's button and fired its action. On a physical iPad the owner saw an earlier build of this page and reported on its wording only. Not known from a device: whether a tap brings up the sheet there, and whether VoiceOver finds and activates the control; see `docs/cases/audio-003-a-tap-at-either-end-of-the-wide-button-brings-up-the-systems-broadcast-sheet.md` and `docs/cases/audio-006-with-voiceover-the-wide-button-is-read-as-its-name-and-activating-it-brings-up-the-sheet.md`.

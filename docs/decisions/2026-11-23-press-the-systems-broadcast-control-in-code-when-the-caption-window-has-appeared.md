date: 2026-11-23
status: accepted
supersedes: none

# Press the system's broadcast control in code when the caption window has appeared

Tapping Start is meant to bring up the system's screen-broadcast sheet without another tap in the app. When the caption window of a starting session has appeared and no broadcast runs, the app owes the user that sheet; as soon as the system's control is on the page, the app presses it once, by sending its inner button the event a tap would.

Why: the owner, after using the app on an iPad, said that Start should bring the sheet up by itself. Before this, Start floated the window and the user had to find the system's control and tap it.

The control has no call that shows its sheet. Sending its button the event leans on how the control is built inside, which the system may change. If there is no button to find, nothing is pressed. What is left then is the wide button on the page, which leans on the same button being there; see `docs/decisions/2026-11-23-lay-the-systems-broadcast-control-over-one-wide-button-while-no-broadcast-runs.md`.

The sheet is asked for when the window has appeared, not at the tap on Start. That is the order the earlier flow led to on a device: the window appeared, and then the user found the control and tapped it. Whether a Picture in Picture window still starts while a sheet is being presented was not tried.

What is owed is used up once and is not kept: it is dropped when the session ends, when the app leaves the front, and when the user presses the control; and, at the moment the control could be pressed, when the session no longer runs, a broadcast has started, or the app is not in front. A window reported again for a session that already had one owes nothing. The rules are in `BroadcastSheetRequest` in JimakuCore.

Status of evidence: the rules are covered by tests of JimakuCore. In an iPad simulator on iOS 27.0, with a build that logged it, the app found the control's button and sent it the event once after Start, and the button's action fired once. The simulator has no screen broadcast and shows no sheet, so whether a sheet follows is not known anywhere; see `docs/cases/audio-002-tapping-start-brings-up-the-systems-broadcast-sheet-without-another-tap.md`, not run.

Not covered: a start that is stopped before its window appears and followed at once by another. The caption window cannot tell which start a late report belongs to. That was so before this change: a late report that the older window closed can end the newer session. What this change adds to it is at most a sheet asked for on behalf of the newer session, which wants one.

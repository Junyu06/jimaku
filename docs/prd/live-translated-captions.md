# Live translated captions

Accepted requirements for the first version. The Status section at the end says what is implemented and what has been verified.

## What the user does

1. Opens Jimaku, picks the spoken language, taps Start.
2. Confirms the system screen-broadcast prompt.
3. A floating caption window appears.
4. Switches to another app and plays a video. The window shows the original line and its translation.
5. Returns to Jimaku to read the captions of this session, or closes the floating window to stop.

## Requirements

- Runs on iPhone and iPad from one Swift codebase.
- Source language is chosen by the user: English or Japanese. No automatic detection.
- Target language is Simplified Chinese.
- The floating window shows two lines by default: the original line and the translated line. The user can switch to translation only.
- Speech is translated while it goes on, without waiting for the recognizer to finalize it, one sentence at a time: a sentence is translated when it has ended, or after about four seconds if it runs on (up to about eight when it offers no place to cut). Speech that has not ended is not translated; the Chinese row shows a dim "…" while it waits.
- Caption text that has been shown as settled does not change and does not move sideways. Rows have fixed lines; when a row is full its lines move up by one. On the original row, text that may still change is dimmer. The few cases where this does not hold are listed in `docs/decisions/2026-11-12-lay-captions-out-in-fixed-lines-that-roll-up.md`.
- The user can switch the translation engine between the Translation framework language packs and the on-device Apple Intelligence model.
- The user can change the caption text size.
- The app keeps a log of the captions of the current session, readable in the app. It is not kept after the app is closed.
- Closing the floating window ends the session. It also stops the screen broadcast if the system allows the app to do so; otherwise the user stops the broadcast from the system indicator.
- No account, no network service, no cost to run.

## Not in the first version

Other languages, automatic language detection, caption history across sessions and its deletion, accounts, export, App Store distribution.

## Accepted when

On a physical iPhone and a physical iPad:

- With an English video and a Japanese video in a video app, and one video in a social feed app, each watched for two to three minutes, the floating window keeps showing Chinese captions a reader can follow.
- Switching the translation engine keeps captions coming.
- Changing the text size and the one-line or two-line mode changes the floating window.
- After returning to the app, the captions of the session just watched are readable.
- Closing the floating window stops the captions.

Running reliably for a full hour is not part of this acceptance.

## Status

All requirements are implemented. Each case under `docs/cases/` records what was checked.

- On a physical iPad (2026-11-12, reported by the owner with screenshots): audio capture, speech recognition, language-pack translation, and the floating window worked together on Japanese videos, in three earlier versions. The first translated only finalized speech and fell behind continuous speech. The second translated speech in progress and kept up, but rewrote and slid its captions so much that they were hard to read. The third kept speech in pieces that do not change, on fixed lines that roll up, with a dimmer provisional translation; the rows held still, but the provisional translation was read and then replaced, and the pieces came too fast. That led to translating a sentence only when it has ended.
- In an iPad simulator: the floating window, captions in fixed lines, translating speech in progress, text size, display mode, the session log, and Apple Intelligence translation.
- Not yet run on a device: the current version. Nothing has run on an iPhone.

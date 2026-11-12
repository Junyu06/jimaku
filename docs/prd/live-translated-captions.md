# Live translated captions

Accepted requirements for the first version. Nothing here is implemented yet unless the Status line of a section says so.

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
- A line is translated once the recognizer has settled on it.
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

- Floating caption window: implemented with scripted demo captions. Seen in an iPad simulator; not verified on a device.
- Audio capture, speech recognition, translation, engine switch, text size, one-line mode, session log: not implemented.

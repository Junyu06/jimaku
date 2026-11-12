# Jimaku

> **Status: first version written; an earlier build has run on a physical iPad.** On 2026-11-12 the owner ran it on an iPad with a Japanese video: audio capture, speech recognition, language-pack translation, and the floating window worked together. Two earlier builds ran there: the first fell behind continuous speech, and the second kept up but rewrote its captions so much that they were hard to read. Captions are now kept in pieces that do not change once shown, on fixed lines that roll up. The current build has only been checked in an iPad simulator, where scripted input stands in for capture, recognition, and language-pack translation. Nothing has run on an iPhone. See `docs/cases/` for what was checked and how.

Jimaku (字幕, Japanese for "subtitles") is a planned iPhone and iPad app for live translated captions over whatever is playing on the device.

The plan: it listens to the audio of other apps, turns the speech into text, translates it, and shows the result in a floating window on top of the app being watched. Everything is meant to run on the device with Apple's built-in frameworks: no account, no server, no subscription.

## How it is meant to work

```
Audio from another app (a video, a stream)
   │  1. Capture     ReplayKit broadcast upload extension
   ▼
Speech
   │  2. Recognize   Speech framework, on-device
   ▼
Source-language text
   │  3. Translate   Translation framework language packs,
   │                 or the on-device Apple Intelligence model
   ▼
Translated text
   │  4. Display     Picture in Picture window
   ▼
Captions floating over the app you are watching
```

Planned use:

1. Open Jimaku, pick the spoken language, tap Start.
2. Confirm the system screen-broadcast prompt.
3. A floating caption window appears.
4. Switch to the app you want to watch. Captions show the original line and the translated line.
5. Return to Jimaku and tap Stop.

## Scope of the first version

- iPhone and iPad, one Swift codebase.
- Source languages: English and Japanese, chosen manually.
- Target language: Simplified Chinese.
- Two caption lines by default (original and translation), adjustable.
- Speech is translated while it goes on. Text that has been shown as settled is meant not to change or slide; the unfinished end is shown dimmer with a provisional translation.
- A switch between two translation engines: Translation framework language packs, and the on-device Apple Intelligence model.
- A log of the current session's captions, readable in the app.
- Closing the floating window ends the session, and also stops the screen broadcast if the system allows the app to do so.

Not in the first version: other languages, automatic language detection, accounts, export, App Store distribution.

## Known limits

These come from the platform, not from choices made here.

- The system asks for screen-broadcast confirmation every time a session starts.
- Audio from DRM-protected playback cannot be captured.
- Phone and FaceTime call audio cannot be captured.
- The system allows one Picture in Picture window at a time, so the app being watched cannot use its own while captions are showing.
- The size of the floating window is limited by the system.

## Open questions

To be answered by running on real devices:

- Whether capture, recognition, and translation keep running reliably in the background for a long session. Broadcast upload extensions have a small memory budget, so audio is handed to the main app for recognition.
- How far the translated line lags behind the speech.
- Whether a free Apple developer account is enough for the required capabilities.
- Whether the Apple Intelligence model is throttled when the app is in the background.
- How readable Japanese-to-Chinese translation is on short, fragmented lines.

## Requirements

- iOS or iPadOS 26 or later.
- Speech recognition and translation language assets downloaded on the device.
- The Apple Intelligence translation option needs a device that supports Apple Intelligence.

## Build and run

See [docs/workflows/run-locally.md](docs/workflows/run-locally.md).

## For contributors and coding agents

Read [AGENTS.md](AGENTS.md) first, then [docs/README.md](docs/README.md).

## License

[MIT](LICENSE)

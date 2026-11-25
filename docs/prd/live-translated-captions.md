# Live translated captions

Accepted requirements for the first version. The Status section at the end says what is implemented and what has been verified.

## What the user does

1. Opens Jimaku, picks the spoken language and the language to translate into, taps Start.
2. Confirms the system screen-broadcast prompt.
3. A floating caption window appears.
4. Switches to another app and plays a video. The window shows the original line and its translation.
5. Returns to Jimaku to read the captions of this session, or closes the floating window to stop.

## Requirements

- Runs on iPhone and iPad from one Swift codebase.
- The user chooses the spoken language and the language captions are translated into. No automatic detection.
- The languages come from one list: English, Japanese, Chinese, Korean, Spanish, French, German, Italian, Portuguese, and Hindi. Chinese is listened for as Mandarin and translated into as Simplified or Traditional. The settings offer the ones this device reports it can recognize and translate. Choosing, on one side, the language that is on the other swaps the two.
- With nothing chosen yet, captions are translated into the first of the device's preferred languages that the list has, from English; or from Japanese into English when that language is English or the list has none of them. A spoken language chosen in the version that had only English and Japanese keeps translating into Simplified Chinese.
- The choice is kept as the user made it. When the device cannot do the chosen pair, a session uses the nearest pair it can, and goes back to the choice when the device can do it. When it can do no pair at all, a session does not start and the app says why. While a session runs, its languages cannot be changed.
- The floating window shows two rows by default: one line of the original above two lines of translation. The user can switch to translation only, and can choose two to five lines of translation; the text keeps its size, and the window grows taller once the lines no longer fit its lowest shape.
- Speech is translated one thing said at a time. A caption ends where the speaker pauses or a sentence ends; its translation appears then, after the one before it, and is not replaced. Speech that runs on with neither is cut after about four seconds (up to about eight when it offers no place to cut). The translation of speech that has not ended is not shown; the translation row shows a dim "…" while it waits.
- Caption text that has been shown as settled does not change and does not move sideways. Rows have fixed lines. On the original row each sentence starts on a new line, and when the row is full its oldest sentence leaves and the rest move up. On the translation row translations follow one another like the sentences of a paragraph; the row fills like a page and starts a new page when the next translation does not fit. On the original row, text that may still change is dimmer. The few cases where this does not hold are listed in `docs/decisions/2026-11-12-lay-captions-out-in-fixed-lines-that-roll-up.md`.
- The on-device model is asked to translate under the system's guardrails for turning text into other text, so that what a sentence is about is less likely to leave a caption without its translation. A sentence the model still refuses by throwing is given the app's own description, which a session shows as a translation error. A refusal the model writes out as its answer is not told apart from a translation.
- The user can switch the translation engine between the Translation framework and the on-device Apple Intelligence model. An engine that cannot translate the chosen languages on this device is not offered, and with one engine left there is nothing to switch.
- When the chosen languages need a language pack that the system offers and has not downloaded, the settings say so and have a button that brings up the system's download. A session started without the pack shows original-language captions and names the pack that is missing; it starts translating when the app learns that the pack has arrived, which it looks for during some eleven minutes after the download sheet closes and each time it comes to the front.
- The user can change the caption text size.
- The app keeps a log of the captions of the current session, readable in the app. It is not kept after the app is closed.
- Closing the floating window ends the session. It also stops the screen broadcast if the system allows the app to do so; otherwise the user stops the broadcast from the system indicator.
- No account, no network service, no cost to run.

## Not in the first version

Languages outside the list, automatic language detection, caption history across sessions and its deletion, accounts, export, App Store distribution.

## Accepted when

On a physical iPhone and a physical iPad:

- With an English video and a Japanese video in a video app, and one video in a social feed app, each watched for two to three minutes, the floating window keeps showing Chinese captions a reader can follow.
- With a video in Chinese and English chosen to translate into, the floating window shows English captions.
- Switching the translation engine keeps captions coming.
- Changing the text size, the display mode, and the number of translation lines changes the floating window.
- After returning to the app, the captions of the session just watched are readable.
- Closing the floating window stops the captions.

Running reliably for a full hour is not part of this acceptance.

## Status

All requirements have code written for them. Each case under `docs/cases/` records what was checked; a requirement whose cases are all `not-run` has not been seen working anywhere, and one whose cases are `simulated` has not been seen working on a device.

- On a physical iPad (2026-11-12, reported by the owner with screenshots): audio capture, speech recognition, language-pack translation, and the floating window worked together on Japanese videos, in four earlier versions. The first translated only finalized speech and fell behind continuous speech. The second translated speech in progress and kept up, but rewrote and slid its captions so much that they were hard to read. The third kept speech in pieces that do not change, on fixed lines that roll up, with a dimmer provisional translation; the rows held still, but the provisional translation was read and then replaced, and the pieces came too fast. That led to translating a sentence only when it has ended. The fourth did that, telling the end of a sentence from the recognizer's guesses; with quick conversation its captions came late and were cut by length, and the owner reported it as unusable. That led to ending a caption where the speaker pauses.
- In an iPad simulator: the floating window, captions in fixed lines, translating speech in progress, text size, display mode, the number of translation lines, the session log, and Apple Intelligence translation.
- On a physical iPad (2026-11-12, logged by the app and reported by the owner): the version that ends a caption where the speaker pauses. See `docs/cases/translation-004-a-caption-appears-when-the-speaker-stops.md`.
- On a physical iPad (2026-11-12, reported by the owner, no screenshots kept): the choice of two to five lines, at text sizes of 40, 30, and 24 columns; the lines were reported as fine and the text as still too large. A step to 60, 50, and 40 columns with more room around the text was tried there too; the small and medium sizes were reported as a little too small. The present small and medium sizes have not been seen on a device.
- Choosing both languages (2026-11-23): in an iPad simulator, the settings listed the languages, swapped the two sides, restored a choice stored by the earlier version, and a session ran with another pair and had its engine changed both ways while it ran. There the recognizer and the language-pack engine are scripted and every language is reported as ready; the Apple Intelligence engine is the host Mac's model, and it translated the scripted text into the chosen target. On a Mac, outside the app, synthesized Mandarin fed to the system recognizer was cut by the app's rules and translated into English by the Translation framework. Not run anywhere at that time: what a device reports and so what the settings list there, a language other than English and Japanese in a real session (run on an iPad since; see the next entry), the download of a language pack and a session picking the pack up, and a session refused because the device can do no pair. See the `language-` cases under `docs/cases/`.
- On a physical iPad (2026-11-23, reported by the owner with one screenshot): the settings for both languages and the engine, and a session with Chinese spoken, English as the target, the Apple Intelligence engine, and the translation only. The entries of the session's captions visible in the screenshot had English translations under the Chinese. One sentence was refused by the model's guardrails; the app showed the system's message for it and the window showed original Chinese. The download of a language pack was not reported on.
- Translating under the permissive guardrails (2026-11-23): on a Mac, given as text, the app's translator code translated three sentences the model's default guardrails refused, and turned a refusal thrown by the default model into the app's own description. Not run in the app or on a device. See `translation-006` and `translation-007` under `docs/cases/`.
- Nothing has run on an iPhone.

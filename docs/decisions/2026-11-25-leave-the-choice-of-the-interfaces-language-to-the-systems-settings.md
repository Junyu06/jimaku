date: 2026-11-25
status: accepted
supersedes: none

# Leave the choice of the interface's language to the system's settings

The interface has two languages, Simplified Chinese and English. Which one shows is the system's decision: it follows the device's preferred languages, and the system's Settings offer a language for Jimaku alone once an app carries more than one. The app has no setting of its own for it. The system shows that row by itself only on a device with more than one preferred language; the app's `Info.plist` sets `UIPrefersShowingLanguageSettings`, which asks for the row on a device with one.

Why: the owner asked for Chinese and English, and asked why the system's settings had no language choice for the app: that is where people look for it. An earlier plan had a row in the app's own settings; the owner said the choice belongs in the system's.

The names of languages come from the system in the interface's language, as before. The caption in the preview is part of the interface: with no session it shows a line in another language and its translation into the interface's language.

Captions, and what the system or an engine reports in its own words inside an error, are not interface text and are shown as they come.

Rejected: a language setting inside the app. It would be a second place for a choice the system already offers, and it would have to restart or redraw the whole interface.

How the two languages are written: `docs/decisions/2026-11-25-keep-the-interfaces-chinese-text-in-the-source-and-its-english-in-string-catalogs.md`.

Status of evidence: in an iPad simulator launched in English, the start page, the page that says why the recording is needed, the start page with a session running and no recording, and the caption window's notice were in English, and the names of languages too; launched in Chinese the start page was as before. See `docs/cases/interface-001-launched-in-english-the-start-page-the-recording-page-and-the-caption-window-show-no-chinese.md`. Not seen anywhere: the language row in the system's Settings (`docs/cases/interface-002-the-systems-settings-offer-a-language-for-jimaku.md`), the extension's messages in English, the permission text in English, and most of the notices, which need a failure to show. The English was written by the assistant and read once by a second model, and has not been read by the owner. In English the app says Screen Recording where the Chinese says 录屏, and names the system's sheet Screen Broadcast as the system does; the Chinese makes the same split.

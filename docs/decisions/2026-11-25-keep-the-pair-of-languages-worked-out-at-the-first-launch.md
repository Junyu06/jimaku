date: 2026-11-25
status: accepted
supersedes: none

# Keep the pair of languages worked out at the first launch

With nothing chosen, the app works out a pair of languages from the device's preferred languages. At the first launch it now keeps that pair as it keeps one the user chose. Before, it worked the pair out again at every launch until the user chose one.

Why: the system's Settings now offer a language for Jimaku alone. Once the user chooses one there, it stands first in the list of preferred languages the app is handed, and the pair worked out from that list changes with it: on a device set to Chinese, a user who never touched the languages and had captions from English into Chinese would get Japanese into English after choosing English for the interface. The interface's language and the languages of the captions are two choices.

Rejected: reading the device's own list, the one kept for every app. In an iPad simulator the app got nothing for it by any of three ways of asking (2026-11-25). That is what those three returned there, not proof that no way exists.

Rejected: leaving it. The change comes without the user touching either language row.

What this gives up: a user who never chose a pair and later changes the device's languages keeps the pair of the first launch. And a language chosen for Jimaku before its first launch is first in the list that launch works from.

Status of evidence: seen in an iPad simulator, where a launch argument stands in for the language chosen for the app; see `docs/cases/interface-004-a-language-chosen-for-the-app-after-the-first-launch-does-not-change-the-pair-of-languages.md`. Not run on a device. That the system puts the app's language first in the list is from Foundation's source, not from a device.

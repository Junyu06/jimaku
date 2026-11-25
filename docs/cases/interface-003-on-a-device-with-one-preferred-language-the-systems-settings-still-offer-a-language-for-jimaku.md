---
area: interface
status: not-run
---

# On a device with one preferred language, the system's Settings still offer a language for Jimaku

- Input: on a device whose preferred languages hold Chinese alone, install the app, open the system's Settings, and go to Jimaku.
- Expected result: Jimaku's page has a Language row offering Simplified Chinese and English.
- Property: the row does not depend on how many languages the user has set up; the app asks for it with `UIPrefersShowingLanguageSettings`.

## Evidence

- Physical device: not run.
- The built app's `Info.plist` carries `UIPrefersShowingLanguageSettings` as true (2026-11-25, simulator build). That is not the row.

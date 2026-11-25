---
area: interface
status: not-run
---

# The system's Settings offer a language for Jimaku

- Input: on a device whose preferred languages include both Chinese and English, install the app, open the system's Settings, go to Jimaku, choose English under Language, and open the app. Then choose Chinese and open it again.
- Expected result: Jimaku's page in Settings has a Language row offering Simplified Chinese and English. After English is chosen the app's interface is in English; after Chinese, in Chinese.
- Property: the interface's language can be chosen for this app alone, in the system's settings.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- The built app carries `en.lproj` and `zh-Hans.lproj`, in the app and in its broadcast extension (2026-11-25, simulator build), which is what the system reads to offer the row. That is not the row.

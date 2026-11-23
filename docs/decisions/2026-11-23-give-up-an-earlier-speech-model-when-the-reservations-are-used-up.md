date: 2026-11-23
status: accepted
supersedes: none

# Give up an earlier speech model when the reservations are used up

Before the app asks the system to download the speech model of a language, it looks at the locales the system has reserved for the app. If there is no room for one more, it releases as many of the first reserved locales as make room, and then asks. If the system refuses all the same, it looks and asks once more: a start that was stopped a moment earlier may have taken the place meanwhile. A start that has been cancelled stops before each of these steps.

Why: the system keeps the speech models of a limited number of locales for an app (`AssetInventory.maximumReservedLocales`, which was 5 on macOS 27.2) and refuses a request beyond that. With two spoken languages the limit could not be reached; with ten it can, and the sixth language would fail to start.

Cost accepted: a language whose reservation was released may have to download its model again the next time it is used. Which reserved locale is released is decided by the order the system lists them in, not by which was used longest ago; the app does not keep that history.

Status of evidence: which locales to release is covered by tests of JimakuCore. That the system refuses a sixth locale, and that releasing one makes room, are from the framework's documentation and were not produced on a device.

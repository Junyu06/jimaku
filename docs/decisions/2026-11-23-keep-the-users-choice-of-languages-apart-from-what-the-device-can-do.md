date: 2026-11-23
status: superseded in part by 2026-11-23-list-both-engines-and-grey-out-the-one-that-cannot-translate-with-the-reason.md: before the first answer the engine row lists both engines. The rest stands.
supersedes: none

# Keep the user's choice of languages apart from what the device can do

The app stores the pair and the engine the user chose, which of the two languages was chosen last, and what was on screen on the other side at that moment. What a session uses is worked out from that and the system's latest answer each time it is needed, and is never stored. A chosen pair the device cannot do gives way to the nearest it can: the side the user chose last is kept and the other gives way first, to what was on screen there before if the device can do that; a side the device cannot do at all gives way too. A pair is one the device can do when it recognizes the spoken language and some engine translates it into the target.

Choosing one language changes that side of the stored choice only. The other side stays as chosen even while it has given way, and comes back when the device can do it. There are two exceptions, both because a language cannot be on both sides. Choosing the language shown on the other side swaps the two that are shown. And when the chosen language of the other side has given way and is the very language now being chosen, it cannot stay chosen there: the one shown in its place becomes the choice.

When the system has answered and there is no pair the device can do, the choice stays as it is and a session does not start; the app says why.

While a session runs its pair is fixed, whatever the system answers and whatever is tapped. When the session ends the pair follows the choice and the device again.

The system is asked more than once. One round of questions waits for the one before it, and an answer to an earlier question than the one already held is dropped.

Why: what the system reports changes while the app runs. A language pack arrives, a model is switched off, an answer comes late. If the pair in use were written back over the choice, a report that was wrong or late for a moment would change what the user chose for good; kept apart, the choice comes back by itself when the device can do it again.

Rejected: settling the stored pair each time the system answers. An answer on its way when the user chose a target then undid the choice, and of two answers the older could arrive last and hide a language pack that had just been downloaded.

Rejected: storing the pair in use when the user changes one side. With a target that had given way, changing the spoken language then replaced the chosen target with the stand-in for good.

Cost accepted: before the first answer the settings show only what is already chosen, and a session started in that moment runs with the chosen pair even if the device turns out not to recognize it; the recognizer then says so.

Status of evidence: covered by tests of JimakuCore (`LanguageSettings`). The cases where answers arrive out of order were not produced on a device or in a simulator.

date: 2026-11-25
status: accepted
supersedes: none

# Write a running session's captions every ten seconds and when the app leaves the front

A session is written to the device when it ends, when the app leaves the front, and every ten seconds while it runs if anything was said since the last write. At the end, what was being said and had not been kept as a caption yet is written as the session's last line, without a translation.

Why: a session ends in several ways the app does not see coming, the commonest being the app closed from the switcher while its captions float over another app. Written only at the end, such a session would be lost whole.

Rejected: writing at each caption. A session writes for hours, and each write is the whole session; a few seconds of captions is what a user stands to lose. A first version looked every thirty seconds; a second model reading the code pointed out that the commonest end, the app swiped away while its captions float over another app, would then lose up to half a minute.

A session that ended and could not be written is kept in memory and tried again at each later save for as long as the app runs.

Cost accepted: a session that ends without the app being told keeps what was said up to its last write; how much that leaves out has not been measured on a device, where the app runs in the background during a session. At Stop, a line whose translation had not arrived is saved with its original alone: the session ends before the translation comes, and it is not waited for.

Status of evidence: nothing here was timed or tried by hand. In an iPad simulator a running session's file appeared on the device before Stop, and sessions ended with Stop were saved with the lines the page showed and, as their last line, what was being said.

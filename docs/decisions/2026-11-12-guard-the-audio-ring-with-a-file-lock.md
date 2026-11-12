date: 2026-11-12
status: accepted
supersedes: the "one writer and one reader, counters written last" protocol in 2026-11-12-hand-audio-from-the-extension-to-the-app-through-a-memory-mapped-ring.md

# Guard the audio ring with a file lock

Samples and their counter are read and written under an advisory file lock (`flock`). Opening the ring takes the same lock. The extension writes with a non-blocking lock and drops the buffer if the app holds the ring at that instant. A file that is not a ring of the expected size is replaced by a new file instead of being resized. The app owns a "capture wanted" flag; the extension ends the broadcast whenever it is false. Every buffer the extension receives updates a heartbeat.

Why: review showed that writing the counter last does not stop a writer from overwriting the region a reader is copying, that two processes opening a new ring could clear each other's data, that shrinking a mapped file can fault another process, that a stop request sent before the broadcast had started was lost, and that a broadcast flag left by an extension the system had ended made the app believe a broadcast was still running.

Rejected: lock-free counters, which need atomics on shared memory and still need overwrite detection. Rejected: a blocking lock in the extension, because a reader suspended while holding it would stall the broadcast.

Cost accepted: the extension occasionally drops a buffer of a few milliseconds when both sides touch the ring at once. One handle must not be shared between threads.

Status of evidence: unit tests cover locking, reopening, replacement, and a concurrent reader and writer. Capture ran on a physical iPad with the earlier, unlocked ring; this version has not yet been checked there.

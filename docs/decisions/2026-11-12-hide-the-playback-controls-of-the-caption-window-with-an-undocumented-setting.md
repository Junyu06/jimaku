date: 2026-11-12
status: accepted
supersedes: none

# Hide the playback controls of the caption window with an undocumented setting

The caption window is a Picture in Picture window, and the system draws playback controls over it when it is touched: skip back, skip forward, play or stop, a LIVE badge, and a progress bar. The app sets the controller's `controlsStyle` to 1 through key-value coding. That leaves the close button and the return-to-app button and drops the rest.

Why: captions have nothing to play, pause, or skip. The controls cover the text while they are up, and the owner, comparing with another caption app whose window shows only close and return, asked for the same.

Rejected: `requiresLinearPlayback = true`, the documented way. In an iPad simulator the skip buttons, the stop button, the LIVE badge, and the progress bar were all still drawn.

Rejected: a video-call Picture in Picture window, which has no playback controls. It is meant for calls, and it would replace the whole way the window is drawn for the sake of the buttons.

Cost accepted:

- `controlsStyle` is not in the public API. A system update may remove it or change what 1 means. The app sets it only if the controller responds to its setter; without it the standard controls come back and nothing else changes.
- An app that uses it may be refused by App Store review. This app is installed from source and is not distributed through the store.
- While the two remaining buttons are up, the system still dims the window.

Status of evidence: in an iPad simulator (iOS 27.0) the window showed only the close and return buttons where it had shown the full controls before. The owner then used it on a physical iPad and reported the window as good; whether the two buttons fade there was not reported.

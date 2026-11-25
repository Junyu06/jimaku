/// The page that says why the screen recording is needed.
///
/// The user can ask for it where the page offers the recording. Once, it comes
/// by itself: before the first session, so that the system's sheet is not the
/// first the user hears of a recording.
public enum RecordingExplanation {
    /// Whether the page is shown before a session starts.
    ///
    /// - Parameters:
    ///   - readBefore: the user has closed the page with its button before.
    ///   - startWouldGoAhead: the tap on the main button would start a session.
    public static func isDueBeforeStart(readBefore: Bool, startWouldGoAhead: Bool) -> Bool {
        startWouldGoAhead && !readBefore
    }

    /// Whether a session starts once the page has left the screen.
    ///
    /// The page takes a moment to go, and the user may have left the app in
    /// it: a session is not started behind their back.
    ///
    /// - Parameters:
    ///   - closedWithButtonBeforeStart: the page stood before a first session
    ///     and was closed with its button.
    ///   - appIsActive: the app is in front and takes touches.
    ///   - sessionIsIdle: no session is starting, running, or stopping.
    public static func startsSessionOnceGone(
        closedWithButtonBeforeStart: Bool, appIsActive: Bool, sessionIsIdle: Bool
    ) -> Bool {
        closedWithButtonBeforeStart && appIsActive && sessionIsIdle
    }
}

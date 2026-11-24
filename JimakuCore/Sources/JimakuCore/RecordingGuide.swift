/// What the start page says about the screen recording once a session's caption
/// window is up.
///
/// A session hears other apps only through a screen broadcast the user starts
/// in a sheet of the system's. The page names the one thing that is missing,
/// and says nothing while sound arrives.
public enum RecordingGuide: Equatable, Sendable {
    /// No broadcast is running. The page offers the button that brings up the
    /// system's sheet.
    case openRecording
    /// A broadcast is running and no sound has arrived for a moment.
    case playSomething
    /// The app cannot receive audio at all, so a broadcast would not help.
    case cannotHear

    /// - Parameter windowIsUp: whether the session's caption window has
    ///   appeared. Before that the page says nothing: the button it would show
    ///   could be tapped while the app is about to ask for the same sheet.
    public static func choose(windowIsUp: Bool, audio: AudioAvailability) -> RecordingGuide? {
        guard windowIsUp else { return nil }
        switch audio {
        case .notBroadcasting: return .openRecording
        case .stalled: return .playSomething
        case .unavailable: return .cannotHear
        case .receiving: return nil
        }
    }
}

/// Whether the app still owes the user the system's broadcast sheet for the
/// session whose caption window just appeared.
///
/// Start should need no second tap in the app, so when the window is up and
/// nothing is being broadcast the app asks for the sheet itself. That is owed
/// from then until the system's control is on the page to be pressed, and is
/// acted on once, or dropped.
public struct BroadcastSheetRequest: Equatable, Sendable {
    public private(set) var isOwed = false

    public init() {}

    /// The caption window reported that it appeared.
    ///
    /// - Parameter sessionWasStarting: whether the session was waiting for its
    ///   window. A window reported again for a session that already had one
    ///   owes nothing.
    public mutating func windowAppeared(sessionWasStarting: Bool, audio: AudioAvailability) {
        guard sessionWasStarting, audio == .notBroadcasting else { return }
        isOwed = true
    }

    /// The system's control can be pressed now. Returns whether to press it.
    /// What was owed is used up either way: a sheet that is no longer wanted,
    /// because the session stopped, a broadcast started, or the user left the
    /// app, is not shown later.
    public mutating func take(sessionRunning: Bool, audio: AudioAvailability, appIsActive: Bool) -> Bool {
        guard isOwed else { return false }
        isOwed = false
        return sessionRunning && audio == .notBroadcasting && appIsActive
    }

    /// The reason for the sheet is gone: the session ended, the user left the
    /// app, or the user pressed the control. What was owed is not kept for
    /// later.
    public mutating func drop() {
        isOwed = false
    }
}

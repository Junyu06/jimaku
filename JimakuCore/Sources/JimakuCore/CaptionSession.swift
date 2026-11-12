/// One captioning session, from the tap on Start until the caption window is gone.
///
/// This type only decides state. The app floats the window, captures audio, and
/// shows captions; it reports what happened here and reads back what to do.
///
/// A session does not run just because Start was tapped, and is not over just
/// because Stop was: the caption window starts and closes on the system's schedule.
/// `starting` and `stopping` cover those gaps, so a window that never appears cannot
/// leave the button on Stop, and a window still closing cannot end the next session.
public struct CaptionSession: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        /// Nothing is running. A session can be started.
        case idle
        /// Start was requested; the caption window has not appeared yet.
        case starting
        /// The caption window is up.
        case running
        /// Stop was requested; the caption window has not finished closing.
        case stopping
    }

    /// What the main button does when tapped.
    public enum PrimaryAction: Equatable, Sendable {
        case start
        case stop
    }

    public private(set) var state: State = .idle

    public init() {}

    /// True from a start request until a stop request or the window going away.
    /// Audio, recognition, and translation run while this is true.
    public var isActive: Bool {
        state == .starting || state == .running
    }

    public var primaryAction: PrimaryAction {
        isActive ? .stop : .start
    }

    /// False while the previous window is still closing: a new session must wait
    /// for it, or its late close would end the new session.
    public var canPerformPrimaryAction: Bool {
        state != .stopping
    }

    // MARK: What the user asks for

    /// Returns false when a start cannot be accepted now.
    @discardableResult
    public mutating func requestStart() -> Bool {
        guard state == .idle else { return false }
        state = .starting
        return true
    }

    /// Returns false when there is nothing to stop.
    @discardableResult
    public mutating func requestStop() -> Bool {
        guard isActive else { return false }
        state = .stopping
        return true
    }

    /// Does what the main button offers. Returns what was done, or nil when the
    /// button cannot be used right now.
    @discardableResult
    public mutating func performPrimaryAction() -> PrimaryAction? {
        guard canPerformPrimaryAction else { return nil }
        let action = primaryAction
        switch action {
        case .start: requestStart()
        case .stop: requestStop()
        }
        return action
    }

    // MARK: What the caption window reports

    public mutating func windowDidStart() {
        // A window that appears after Stop was requested does not revive the session;
        // the app closes it.
        guard state == .starting else { return }
        state = .running
    }

    public mutating func windowFailedToStart() {
        guard state == .starting || state == .stopping else { return }
        state = .idle
    }

    /// The window is gone, whether the app closed it, the user did, or the system did.
    public mutating func windowDidClose() {
        state = .idle
    }
}

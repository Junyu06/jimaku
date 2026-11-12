/// One captioning session: from the moment the user taps Start until captions stop.
///
/// This type only tracks state. Capturing audio, recognizing speech, and showing
/// captions are done by the app, which reads `state` and calls `start()` and `stop()`.
public struct CaptionSession: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case idle
        case running
    }

    /// What the main button does when tapped.
    public enum PrimaryAction: Equatable, Sendable {
        case start
        case stop
    }

    public private(set) var state: State = .idle

    public init() {}

    public var primaryAction: PrimaryAction {
        switch state {
        case .idle: .start
        case .running: .stop
        }
    }

    public mutating func start() {
        state = .running
    }

    public mutating func stop() {
        state = .idle
    }

    public mutating func performPrimaryAction() {
        switch primaryAction {
        case .start: start()
        case .stop: stop()
        }
    }
}

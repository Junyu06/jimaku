/// What is known about the audio coming from the broadcast extension.
public enum AudioAvailability: Equatable, Sendable {
    /// The shared ring could not be opened, so no audio can ever arrive.
    case unavailable
    /// No screen broadcast is running.
    case notBroadcasting
    /// A broadcast is running and audio is arriving.
    case receiving
    /// A broadcast is running but no audio has arrived for a moment.
    case stalled
}

/// What the caption window says while it has no caption to show.
///
/// The message names the one thing the session is waiting for. Recognition and
/// translation are reported separately, so a translation problem is never shown as
/// a recognition problem.
public enum CaptionPlaceholder: Equatable, Sendable {
    public enum Readiness: Equatable, Sendable {
        case preparing
        case ready
        case failed
    }

    case recognitionFailed
    case preparingRecognition
    case audioUnavailable
    case waitingForBroadcast
    case noSound
    case listening
    case preparingTranslation
    case translating
    case translationUnavailable

    /// - Parameter hasSpeech: whether anything has been recognized in this session.
    public static func choose(
        recognition: Readiness,
        audio: AudioAvailability,
        translation: Readiness,
        mode: CaptionStyle.Mode,
        hasSpeech: Bool
    ) -> CaptionPlaceholder {
        switch recognition {
        case .failed: return .recognitionFailed
        case .preparing: return .preparingRecognition
        case .ready: break
        }

        // Speech exists but there is no caption: the only way that happens is
        // translation-only mode waiting for a translation.
        if hasSpeech, mode == .translationOnly {
            switch translation {
            case .failed: return .translationUnavailable
            case .preparing: return .preparingTranslation
            case .ready: return .translating
            }
        }

        switch audio {
        case .unavailable: return .audioUnavailable
        case .notBroadcasting: return .waitingForBroadcast
        case .stalled: return .noSound
        case .receiving: return .listening
        }
    }
}

extension CaptionStyle.Mode {
    /// The mode to draw with. Translation-only makes no sense when translation
    /// cannot run, so it falls back to showing the original line.
    public func effective(translationAvailable: Bool) -> CaptionStyle.Mode {
        translationAvailable ? self : .originalAndTranslation
    }
}

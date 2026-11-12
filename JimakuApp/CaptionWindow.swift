import AVFoundation
import AVKit
import JimakuCore

/// The floating caption window, built on Picture in Picture.
///
/// iOS does not let an app draw over other apps. Picture in Picture is the system
/// window that stays on screen across apps, so captions are rendered as video
/// frames and shown there.
@MainActor
final class CaptionWindow: NSObject {
    /// The layer that shows captions inside the app. The floating window mirrors it.
    let displayLayer = AVSampleBufferDisplayLayer()

    /// Called when the floating window is gone, whether the user closed it, the
    /// system stopped it, or it failed to start.
    var onClosed: (() -> Void)?

    var isSupported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }
    var isFloating: Bool { controller?.isPictureInPictureActive ?? false }

    private let renderer = CaptionFrameRenderer()
    private var controller: AVPictureInPictureController?
    private var possibleObservation: NSKeyValueObservation?
    private var lines = CaptionLines(original: "", translation: "")
    private var audioLevel: Double?
    private var wantsToFloat = false

    /// Sets up the audio session and the Picture in Picture controller. Safe to call
    /// more than once.
    func prepare() {
        guard controller == nil else { return }

        // Picture in Picture needs a playback audio session. Mixing with others keeps
        // the app being watched audible.
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
        try? audioSession.setActive(true)

        displayLayer.videoGravity = .resizeAspect
        render()

        guard isSupported else { return }
        let source = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: self
        )
        let controller = AVPictureInPictureController(contentSource: source)
        controller.delegate = self
        self.controller = controller
        possibleObservation = controller.observe(\.isPictureInPicturePossible, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in self?.startIfWanted() }
        }
    }

    func show(_ lines: CaptionLines) {
        guard lines != self.lines else { return }
        self.lines = lines
        render()
    }

    /// Shows how loud the incoming audio is, 0...1. Nil hides the meter.
    func show(audioLevel: Double?) {
        // The meter is a few hundred pixels wide; smaller changes are not visible.
        let rounded = audioLevel.map { ($0 * 200).rounded() / 200 }
        guard rounded != self.audioLevel else { return }
        self.audioLevel = rounded
        render()
    }

    /// Asks the system to float the window. If the system is not ready yet, the
    /// window floats as soon as it is.
    func float() {
        wantsToFloat = true
        startIfWanted()
    }

    func close() {
        wantsToFloat = false
        controller?.stopPictureInPicture()
    }

    private func startIfWanted() {
        guard wantsToFloat, let controller, controller.isPictureInPicturePossible,
            !controller.isPictureInPictureActive
        else { return }
        controller.startPictureInPicture()
    }

    private func render() {
        guard let sampleBuffer = renderer.makeSampleBuffer(for: lines, audioLevel: audioLevel) else { return }
        let sampleRenderer = displayLayer.sampleBufferRenderer
        if sampleRenderer.status == .failed {
            sampleRenderer.flush()
        }
        sampleRenderer.enqueue(sampleBuffer)
    }

    private func didClose() {
        wantsToFloat = false
        onClosed?()
    }
}

extension CaptionWindow: @preconcurrency AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        didClose()
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        didClose()
    }
}

extension CaptionWindow: @preconcurrency AVPictureInPictureSampleBufferPlaybackDelegate {
    // Captions are a live stream: there is nothing to pause, seek, or skip.

    func pictureInPictureController(_ controller: AVPictureInPictureController, setPlaying playing: Bool) {}

    func pictureInPictureControllerTimeRangeForPlayback(_ controller: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ controller: AVPictureInPictureController) -> Bool {
        false
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
        render()
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

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

    /// Called when the floating window has appeared.
    var onStarted: (() -> Void)?

    /// Called when the floating window could not appear, with the reason.
    var onFailedToStart: ((Error) -> Void)?

    /// Called when the floating window is gone, whether the app closed it, the user
    /// did, or the system did.
    var onClosed: (() -> Void)?

    var isSupported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }
    var isFloating: Bool { controller?.isPictureInPictureActive ?? false }

    private let renderer = CaptionFrameRenderer()
    private var controller: AVPictureInPictureController?
    private var possibleObservation: NSKeyValueObservation?
    private var content = CaptionContent.rows([])
    /// The height of the frames drawn, in pixels. The window takes its shape
    /// from it.
    private(set) var frameHeight = CaptionFrame.minimumHeight
    private var audioLevel: Double?
    private var wantsToFloat = false

    /// Sets up the Picture in Picture controller. Safe to call more than once.
    func prepare() {
        guard controller == nil else { return }

        // Picture in Picture needs a playback audio session. Mixing with others keeps
        // the app being watched audible. The session is only activated while the
        // window floats.
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .moviePlayback,
            options: [.mixWithOthers]
        )

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

    /// Shows `content` in a frame of the given height. A layout with more lines
    /// needs a taller frame; the window changes shape to match.
    func show(_ content: CaptionContent, frameHeight: Double) {
        guard content != self.content || frameHeight != self.frameHeight else { return }
        self.content = content
        self.frameHeight = frameHeight
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
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            onFailedToStart?(error)
            return
        }
        wantsToFloat = true
        startIfWanted()
    }

    /// Closes the window. `onClosed` follows: at once if the window never appeared,
    /// otherwise when the system has finished closing it.
    func close() {
        wantsToFloat = false
        if let controller, controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            didClose()
        }
    }

    /// Gives up on the current system window without waiting for it: it is detached,
    /// so nothing it reports later is passed on, and a fresh one is prepared.
    func abandon() {
        wantsToFloat = false
        possibleObservation = nil
        controller?.delegate = nil
        controller?.stopPictureInPicture()
        controller = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        prepare()
    }

    private func startIfWanted() {
        guard wantsToFloat, let controller, controller.isPictureInPicturePossible,
            !controller.isPictureInPictureActive
        else { return }
        controller.startPictureInPicture()
    }

    private func render() {
        guard let sampleBuffer = renderer.makeSampleBuffer(for: content, height: frameHeight, audioLevel: audioLevel) else { return }
        let sampleRenderer = displayLayer.sampleBufferRenderer
        if sampleRenderer.status == .failed {
            sampleRenderer.flush()
        }
        sampleRenderer.enqueue(sampleBuffer)
    }

    private func didClose() {
        wantsToFloat = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        onClosed?()
    }
}

extension CaptionWindow: @preconcurrency AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        // The window can appear after it was asked to close; close it again.
        guard wantsToFloat else {
            controller.stopPictureInPicture()
            return
        }
        onStarted?()
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        didClose()
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        wantsToFloat = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        onFailedToStart?(error)
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

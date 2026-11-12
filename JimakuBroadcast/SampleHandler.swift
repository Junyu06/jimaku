import AVFoundation
import CoreMedia
import JimakuCore
import ReplayKit

/// Receives the audio other apps play and drops it into the shared ring.
///
/// Keep this small. The system ends a broadcast extension that uses too much memory,
/// so recognition and translation run in the app, not here.
final class SampleHandler: RPBroadcastSampleHandler {
    private var ring: AudioRing?
    private var converter: AVAudioConverter?
    private var converterInputFormat: AVAudioFormat?
    private let ringFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: Double(AudioRing.sampleRate),
        channels: 1,
        interleaved: true
    )

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        guard let url = SharedAudio.ringURL(), let ring = try? AudioRing(url: url) else {
            finishBroadcastWithError(Self.error("Jimaku 打不开共享的音频缓冲。"))
            return
        }
        ring.isStopRequested = false
        ring.isBroadcasting = true
        self.ring = ring
    }

    override func broadcastFinished() {
        ring?.isBroadcasting = false
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard let ring else { return }

        // The app cannot end a system broadcast itself, so it asks through the ring.
        if ring.isStopRequested {
            ring.isStopRequested = false
            ring.isBroadcasting = false
            self.ring = nil
            finishBroadcastWithError(Self.error("字幕已停止。"))
            return
        }

        guard sampleBufferType == .audioApp, let converted = convert(sampleBuffer),
            let samples = converted.int16ChannelData
        else { return }
        ring.write(UnsafeBufferPointer(start: samples[0], count: Int(converted.frameLength)))
    }

    /// Converts a buffer from whatever format the system delivers to the ring's
    /// 16 kHz mono format.
    private func convert(_ sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        guard let ringFormat, let description = CMSampleBufferGetFormatDescription(sampleBuffer) else { return nil }
        let inputFormat = AVAudioFormat(cmAudioFormatDescription: description)
        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard frameCount > 0, let input = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frameCount)
        else { return nil }
        input.frameLength = frameCount
        guard
            CMSampleBufferCopyPCMDataIntoAudioBufferList(
                sampleBuffer,
                at: 0,
                frameCount: Int32(frameCount),
                into: input.mutableAudioBufferList
            ) == noErr
        else { return nil }

        // One converter is kept across buffers so resampling stays continuous.
        if converter == nil || converterInputFormat != inputFormat {
            converter = AVAudioConverter(from: inputFormat, to: ringFormat)
            converterInputFormat = inputFormat
        }
        guard let converter else { return nil }

        let ratio = ringFormat.sampleRate / inputFormat.sampleRate
        let capacity = AVAudioFrameCount((Double(frameCount) * ratio).rounded(.up)) + 32
        guard let output = AVAudioPCMBuffer(pcmFormat: ringFormat, frameCapacity: capacity) else { return nil }

        var conversionError: NSError?
        nonisolated(unsafe) var pending: AVAudioPCMBuffer? = input
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            guard let buffer = pending else {
                inputStatus.pointee = .noDataNow
                return nil
            }
            pending = nil
            inputStatus.pointee = .haveData
            return buffer
        }
        guard status != .error, output.frameLength > 0 else { return nil }
        return output
    }

    private static func error(_ message: String) -> NSError {
        NSError(domain: "Jimaku", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

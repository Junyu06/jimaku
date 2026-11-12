import AVFoundation
import JimakuCore

/// Converts audio from the shared ring's format (16 kHz, mono, 16-bit) to the
/// format a consumer asks for.
final class PCMConverter {
    private let source: AVAudioFormat
    private let target: AVAudioFormat
    private let converter: AVAudioConverter

    init?(to target: AVAudioFormat) {
        guard
            let source = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: Double(AudioRing.sampleRate),
                channels: 1,
                interleaved: true
            ),
            let converter = AVAudioConverter(from: source, to: target)
        else { return nil }
        self.source = source
        self.target = target
        self.converter = converter
    }

    func convert(_ samples: [Int16]) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty,
            let input = AVAudioPCMBuffer(pcmFormat: source, frameCapacity: AVAudioFrameCount(samples.count)),
            let channel = input.int16ChannelData
        else { return nil }
        samples.withUnsafeBufferPointer { channel[0].update(from: $0.baseAddress!, count: samples.count) }
        input.frameLength = AVAudioFrameCount(samples.count)

        let ratio = target.sampleRate / source.sampleRate
        let capacity = AVAudioFrameCount((Double(samples.count) * ratio).rounded(.up)) + 32
        guard let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return nil }

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
}

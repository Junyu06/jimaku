import Foundation
import JimakuCore

/// The app's end of the shared audio ring: reads what the broadcast extension wrote
/// and tells the extension whether a session wants audio.
@MainActor
final class AudioMonitor {
    private let ring: AudioRing?
    private var position: UInt64 = 0

    init() {
        ring = SharedAudio.ringURL().flatMap { try? AudioRing(url: $0) }
    }

    var status: AudioAvailability {
        guard let ring else { return .unavailable }
        return .assess(
            isBroadcasting: ring.isBroadcasting,
            lastHeartbeat: ring.lastHeartbeatTime,
            lastWrite: ring.lastWriteTime,
            now: Date().timeIntervalSinceReferenceDate
        )
    }

    /// A session wants audio. Anything written before now is skipped.
    func beginCapture() {
        guard let ring else { return }
        ring.isCaptureWanted = true
        position = ring.writeCount
    }

    /// No session wants audio. The extension ends the broadcast when it sees this;
    /// the app has no direct way to stop a system broadcast.
    func endCapture() {
        ring?.isCaptureWanted = false
    }

    /// The samples that arrived since the last call.
    func readNewSamples() -> [Int16] {
        ring?.read(from: &position, max: AudioRing.sampleRate * 2) ?? []
    }

    #if targetEnvironment(simulator)
        /// The simulator has no screen broadcast, so this writes a tone that pulses on
        /// and off into the ring, standing in for the extension. Simulator only.
        func writeSimulatedAudio(elapsed: Double, duration: Double) {
            guard let ring else { return }
            ring.isBroadcasting = true
            let count = Int(duration * Double(AudioRing.sampleRate))
            let loud = Int(elapsed) % 2 == 0
            let samples = (0..<count).map { index -> Int16 in
                guard loud else { return 0 }
                let phase = 2 * Double.pi * 440 * Double(index) / Double(AudioRing.sampleRate)
                return Int16(sin(phase) * 9000)
            }
            ring.write(samples)
        }

        func endSimulatedBroadcast() {
            ring?.isBroadcasting = false
        }
    #endif
}

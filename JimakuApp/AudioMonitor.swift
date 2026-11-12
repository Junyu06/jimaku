import Foundation
import JimakuCore

/// The app's end of the shared audio ring: reads what the broadcast extension wrote.
@MainActor
final class AudioMonitor {
    enum Status: Equatable {
        /// The shared ring could not be opened, so no audio can ever arrive.
        case unavailable
        /// No screen broadcast is running.
        case notBroadcasting
        /// A broadcast is running and audio is arriving.
        case receiving
        /// A broadcast is running but no audio has arrived for a moment.
        case stalled
    }

    private let ring: AudioRing?
    private var position: UInt64 = 0

    init() {
        ring = SharedAudio.ringURL().flatMap { try? AudioRing(url: $0) }
    }

    var status: Status {
        guard let ring else { return .unavailable }
        guard ring.isBroadcasting else { return .notBroadcasting }
        let sinceLastWrite = Date().timeIntervalSinceReferenceDate - ring.lastWriteTime
        return sinceLastWrite < 1.5 ? .receiving : .stalled
    }

    /// Skips anything written before now, so a new session starts with fresh audio.
    func skipToNow() {
        position = ring?.writeCount ?? 0
    }

    /// The samples that arrived since the last call.
    func readNewSamples() -> [Int16] {
        ring?.read(from: &position, max: AudioRing.sampleRate * 2) ?? []
    }

    /// Asks the extension to end the screen broadcast. The app has no direct way to
    /// stop a system broadcast.
    func requestBroadcastStop() {
        guard let ring, ring.isBroadcasting else { return }
        ring.isStopRequested = true
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

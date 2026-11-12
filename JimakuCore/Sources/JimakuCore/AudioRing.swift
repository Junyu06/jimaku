import Foundation

public enum AudioRingError: Error, Equatable {
    case cannotOpen(errno: Int32)
    case cannotResize(errno: Int32)
    case cannotMap(errno: Int32)
}

/// A fixed-size ring of 16-bit mono audio samples in a memory-mapped file, shared
/// between the broadcast extension, which writes, and the app, which reads.
///
/// The extension has a small memory budget and cannot run speech recognition, so it
/// only drops samples here. A mapped file needs no connection between the two
/// processes: either side can start, stop, or crash without the other noticing more
/// than a pause in the data.
///
/// Samples and their counter are read and written under an advisory file lock, so a
/// reader never sees a half-written region and two processes opening the ring at the
/// same moment cannot clear each other's data. The lock is per handle: use one
/// handle per thread. A reader that falls more than one buffer behind loses the
/// oldest samples and continues from the newest.
public final class AudioRing {
    /// Sample rate of the audio stored in the ring.
    public static let sampleRate = 16_000

    /// Ten seconds of audio.
    public static let defaultCapacity = sampleRate * 10

    /// Number of samples the ring holds.
    public let capacity: Int

    private static let magic: UInt32 = 0x4A4D_4B41  // "JMKA"
    private static let version: UInt32 = 2
    private static let headerSize = 64

    private enum Offset {
        static let magic = 0
        static let version = 4
        static let sampleRate = 8
        static let capacity = 12
        static let writeCount = 16
        static let broadcasting = 24
        static let captureWanted = 28
        static let lastWriteTime = 32
        static let heartbeatTime = 40
    }

    private let descriptor: Int32
    private let base: UnsafeMutableRawPointer
    private let mappedSize: Int

    /// Opens the ring at `url`, creating it if needed. A file that is not a ring of
    /// this capacity is replaced by a new file; handles on the old one keep working
    /// on the old data and no longer share with new ones.
    public init(url: URL, capacity: Int = AudioRing.defaultCapacity) throws(AudioRingError) {
        precondition(capacity > 0, "capacity must be positive")
        self.capacity = capacity
        let size = Self.headerSize + capacity * MemoryLayout<Int16>.stride
        mappedSize = size

        var opened: (descriptor: Int32, isNew: Bool)?
        var lastError: Int32 = 0
        for _ in 0..<8 where opened == nil {
            let candidate = open(url.path, O_RDWR | O_CREAT, 0o644)
            guard candidate >= 0 else {
                lastError = errno
                continue
            }
            flock(candidate, LOCK_EX)

            // Another process may have replaced the file while this one waited.
            var mine = stat()
            var current = stat()
            guard fstat(candidate, &mine) == 0, stat(url.path, &current) == 0, mine.st_ino == current.st_ino else {
                flock(candidate, LOCK_UN)
                close(candidate)
                continue
            }

            if mine.st_size == 0 {
                guard ftruncate(candidate, off_t(size)) == 0 else {
                    let code = errno
                    flock(candidate, LOCK_UN)
                    close(candidate)
                    throw .cannotResize(errno: code)
                }
                opened = (candidate, true)
            } else if Int(mine.st_size) == size {
                opened = (candidate, false)
            } else {
                // Not a ring of this capacity. Resizing it could cut memory out from
                // under a process that still has the old file mapped, so leave that
                // file alone and start a new one under the same name.
                unlink(url.path)
                flock(candidate, LOCK_UN)
                close(candidate)
            }
        }
        guard let opened else { throw .cannotOpen(errno: lastError) }
        descriptor = opened.descriptor

        guard let mapped = mmap(nil, size, PROT_READ | PROT_WRITE, MAP_SHARED, descriptor, 0),
            mapped != MAP_FAILED
        else {
            let code = errno
            flock(descriptor, LOCK_UN)
            close(descriptor)
            throw .cannotMap(errno: code)
        }
        base = mapped

        if opened.isNew || !headerIsValid {
            memset(base, 0, size)
            store(Self.version, at: Offset.version)
            store(UInt32(Self.sampleRate), at: Offset.sampleRate)
            store(UInt32(capacity), at: Offset.capacity)
            store(Self.magic, at: Offset.magic)
        }
        flock(descriptor, LOCK_UN)
    }

    deinit {
        munmap(base, mappedSize)
        close(descriptor)
    }

    // MARK: Shared state

    /// Total number of samples ever written. It only grows.
    public var writeCount: UInt64 {
        locked { load(UInt64.self, at: Offset.writeCount) }
    }

    /// Time of the last write, in seconds since the reference date. Zero if nothing
    /// has been written.
    public var lastWriteTime: Double {
        load(Double.self, at: Offset.lastWriteTime)
    }

    /// Time the writer last showed it is alive, by writing or by `heartbeat(at:)`.
    public var lastHeartbeatTime: Double {
        load(Double.self, at: Offset.heartbeatTime)
    }

    /// Set by the extension while a broadcast is running. If the system ends the
    /// extension without warning this stays set, so readers must also check
    /// `lastHeartbeatTime`; see `AudioAvailability.assess`.
    public var isBroadcasting: Bool {
        get { load(UInt32.self, at: Offset.broadcasting) != 0 }
        set { store(UInt32(newValue ? 1 : 0), at: Offset.broadcasting) }
    }

    /// Set by the app while a caption session wants audio. Only the app changes it;
    /// the extension ends the broadcast whenever it is false. Because the extension
    /// never clears it, a stop requested before the broadcast has started is not lost.
    public var isCaptureWanted: Bool {
        get { load(UInt32.self, at: Offset.captureWanted) != 0 }
        set { store(UInt32(newValue ? 1 : 0), at: Offset.captureWanted) }
    }

    /// Records that the writer is alive without writing audio.
    public func heartbeat(at time: Double = Date().timeIntervalSinceReferenceDate) {
        store(time, at: Offset.heartbeatTime)
    }

    // MARK: Writing

    public func write(_ samples: [Int16], at time: Double = Date().timeIntervalSinceReferenceDate) {
        samples.withUnsafeBufferPointer { samples in
            locked { writeLocked(samples, at: time) }
        }
    }

    /// Writes unless another handle holds the ring right now. Returns false, having
    /// written nothing, when it does. The extension uses this so that a reader which
    /// is suspended at the wrong moment can never block the broadcast.
    public func tryWrite(
        _ samples: UnsafeBufferPointer<Int16>,
        at time: Double = Date().timeIntervalSinceReferenceDate
    ) -> Bool {
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else { return false }
        defer { flock(descriptor, LOCK_UN) }
        writeLocked(samples, at: time)
        return true
    }

    private func writeLocked(_ samples: UnsafeBufferPointer<Int16>, at time: Double) {
        guard let source = samples.baseAddress, !samples.isEmpty else { return }
        let start = load(UInt64.self, at: Offset.writeCount)

        // Of a write larger than the ring, only the newest samples can be kept.
        let skipped = max(samples.count - capacity, 0)
        let kept = samples.count - skipped
        let index = Int((start + UInt64(skipped)) % UInt64(capacity))
        let firstPart = min(kept, capacity - index)
        data.advanced(by: index).update(from: source.advanced(by: skipped), count: firstPart)
        if kept > firstPart {
            data.update(from: source.advanced(by: skipped + firstPart), count: kept - firstPart)
        }

        store(time, at: Offset.lastWriteTime)
        store(time, at: Offset.heartbeatTime)
        store(start + UInt64(samples.count), at: Offset.writeCount)
    }

    // MARK: Reading

    /// Returns up to `max` samples written since `position` and advances `position`
    /// past them. If the reader fell more than one buffer behind, the oldest samples
    /// are skipped. A position ahead of the writer is pulled back to the writer.
    public func read(from position: inout UInt64, max: Int) -> [Int16] {
        var current = position
        let samples: [Int16] = locked {
            let written = load(UInt64.self, at: Offset.writeCount)
            if current > written {
                current = written
                return []
            }
            if written - current > UInt64(capacity) {
                current = written - UInt64(capacity)
            }
            let count = Swift.min(max, Int(written - current))
            guard count > 0 else { return [] }

            let index = Int(current % UInt64(capacity))
            let firstPart = Swift.min(count, capacity - index)
            var samples = [Int16](repeating: 0, count: count)
            samples.withUnsafeMutableBufferPointer { destination in
                guard let target = destination.baseAddress else { return }
                target.update(from: data.advanced(by: index), count: firstPart)
                if count > firstPart {
                    target.advanced(by: firstPart).update(from: data, count: count - firstPart)
                }
            }
            current += UInt64(count)
            return samples
        }
        position = current
        return samples
    }

    // MARK: Raw access

    private func locked<Result>(_ body: () -> Result) -> Result {
        flock(descriptor, LOCK_EX)
        defer { flock(descriptor, LOCK_UN) }
        return body()
    }

    private var data: UnsafeMutablePointer<Int16> {
        base.advanced(by: Self.headerSize).assumingMemoryBound(to: Int16.self)
    }

    private var headerIsValid: Bool {
        load(UInt32.self, at: Offset.magic) == Self.magic
            && load(UInt32.self, at: Offset.version) == Self.version
            && load(UInt32.self, at: Offset.sampleRate) == UInt32(Self.sampleRate)
            && load(UInt32.self, at: Offset.capacity) == UInt32(capacity)
    }

    private func load<Value>(_ type: Value.Type, at offset: Int) -> Value {
        base.load(fromByteOffset: offset, as: type)
    }

    private func store<Value>(_ value: Value, at offset: Int) {
        base.storeBytes(of: value, toByteOffset: offset, as: Value.self)
    }
}

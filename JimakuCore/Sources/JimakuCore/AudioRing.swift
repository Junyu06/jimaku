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
/// There is one writer and one reader. Counters are 64-bit values at aligned offsets,
/// written by the writer only after the samples they cover, so a reader never sees a
/// count ahead of the data. A reader that falls more than one buffer behind loses the
/// oldest samples and continues from the newest.
public final class AudioRing {
    /// Sample rate of the audio stored in the ring.
    public static let sampleRate = 16_000

    /// Ten seconds of audio.
    public static let defaultCapacity = sampleRate * 10

    /// Number of samples the ring holds.
    public let capacity: Int

    private static let magic: UInt32 = 0x4A4D_4B41  // "JMKA"
    private static let version: UInt32 = 1
    private static let headerSize = 64

    private enum Offset {
        static let magic = 0
        static let version = 4
        static let sampleRate = 8
        static let capacity = 12
        static let writeCount = 16
        static let broadcasting = 24
        static let stopRequested = 28
        static let lastWriteTime = 32
    }

    private let base: UnsafeMutableRawPointer
    private let mappedSize: Int

    /// Opens the ring at `url`, creating it if needed. A file that is not a ring of
    /// this capacity is replaced by an empty ring.
    public init(url: URL, capacity: Int = AudioRing.defaultCapacity) throws(AudioRingError) {
        precondition(capacity > 0, "capacity must be positive")
        self.capacity = capacity
        mappedSize = Self.headerSize + capacity * MemoryLayout<Int16>.stride

        let descriptor = open(url.path, O_RDWR | O_CREAT, 0o644)
        guard descriptor >= 0 else { throw .cannotOpen(errno: errno) }
        defer { close(descriptor) }

        var status = stat()
        fstat(descriptor, &status)
        let sizeMatches = Int(status.st_size) == mappedSize
        if !sizeMatches {
            guard ftruncate(descriptor, off_t(mappedSize)) == 0 else { throw .cannotResize(errno: errno) }
        }

        guard let mapped = mmap(nil, mappedSize, PROT_READ | PROT_WRITE, MAP_SHARED, descriptor, 0),
            mapped != MAP_FAILED
        else { throw .cannotMap(errno: errno) }
        base = mapped

        if !sizeMatches || !headerIsValid {
            memset(base, 0, mappedSize)
            store(Self.version, at: Offset.version)
            store(UInt32(Self.sampleRate), at: Offset.sampleRate)
            store(UInt32(capacity), at: Offset.capacity)
            store(Self.magic, at: Offset.magic)
        }
    }

    deinit {
        munmap(base, mappedSize)
    }

    // MARK: Shared state

    /// Total number of samples ever written. It only grows.
    public var writeCount: UInt64 {
        load(UInt64.self, at: Offset.writeCount)
    }

    /// Time of the last write, in seconds since the reference date. Zero if nothing
    /// has been written.
    public var lastWriteTime: Double {
        load(Double.self, at: Offset.lastWriteTime)
    }

    /// Set by the extension while a broadcast is running.
    public var isBroadcasting: Bool {
        get { load(UInt32.self, at: Offset.broadcasting) != 0 }
        set { store(UInt32(newValue ? 1 : 0), at: Offset.broadcasting) }
    }

    /// Set by the app to ask the extension to end the broadcast.
    public var isStopRequested: Bool {
        get { load(UInt32.self, at: Offset.stopRequested) != 0 }
        set { store(UInt32(newValue ? 1 : 0), at: Offset.stopRequested) }
    }

    // MARK: Writing

    public func write(_ samples: [Int16], at time: Double = Date().timeIntervalSinceReferenceDate) {
        samples.withUnsafeBufferPointer { write($0, at: time) }
    }

    public func write(
        _ samples: UnsafeBufferPointer<Int16>,
        at time: Double = Date().timeIntervalSinceReferenceDate
    ) {
        guard let source = samples.baseAddress, !samples.isEmpty else { return }
        let start = writeCount

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
        store(start + UInt64(samples.count), at: Offset.writeCount)
    }

    // MARK: Reading

    /// Returns up to `max` samples written since `position` and advances `position`
    /// past them. If the reader fell more than one buffer behind, the oldest samples
    /// are skipped. A position ahead of the writer is pulled back to the writer.
    public func read(from position: inout UInt64, max: Int) -> [Int16] {
        let written = writeCount
        if position > written {
            position = written
            return []
        }
        if written - position > UInt64(capacity) {
            position = written - UInt64(capacity)
        }
        let count = Swift.min(max, Int(written - position))
        guard count > 0 else { return [] }

        let index = Int(position % UInt64(capacity))
        let firstPart = Swift.min(count, capacity - index)
        var samples = [Int16](repeating: 0, count: count)
        samples.withUnsafeMutableBufferPointer { destination in
            guard let target = destination.baseAddress else { return }
            target.update(from: data.advanced(by: index), count: firstPart)
            if count > firstPart {
                target.advanced(by: firstPart).update(from: data, count: count - firstPart)
            }
        }
        position += UInt64(count)
        return samples
    }

    // MARK: Raw access

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

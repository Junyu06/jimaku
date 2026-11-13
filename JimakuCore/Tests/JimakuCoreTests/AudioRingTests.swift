import Foundation
import JimakuCore
import Testing

@Suite("AudioRing")
struct AudioRingTests {
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("audio-ring-\(UUID().uuidString).bin")
    }

    @Test("A new ring is empty and idle")
    func newRingIsEmpty() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 8)
        #expect(ring.writeCount == 0)
        #expect(ring.isBroadcasting == false)
        #expect(ring.isCaptureWanted == false)
        #expect(ring.lastHeartbeatTime == 0)
        var position: UInt64 = 0
        #expect(ring.read(from: &position, max: 100).isEmpty)
        #expect(position == 0)
    }

    @Test("Samples come back in the order they were written")
    func writeThenRead() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 8)
        ring.write([1, 2, 3])
        var position: UInt64 = 0
        #expect(ring.read(from: &position, max: 100) == [1, 2, 3])
        #expect(position == 3)
        #expect(ring.read(from: &position, max: 100).isEmpty)
    }

    @Test("A second handle on the same file sees what the first one wrote")
    func twoHandlesShareData() throws {
        let url = temporaryURL()
        let writer = try AudioRing(url: url, capacity: 8)
        let reader = try AudioRing(url: url, capacity: 8)
        writer.write([10, -20, 30])
        var position: UInt64 = 0
        #expect(reader.read(from: &position, max: 100) == [10, -20, 30])
        writer.write([40])
        #expect(reader.read(from: &position, max: 100) == [40])
    }

    @Test("Writes wrap around the end of the buffer without losing order")
    func wrapsAround() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 4)
        var position: UInt64 = 0
        ring.write([1, 2, 3])
        #expect(ring.read(from: &position, max: 100) == [1, 2, 3])
        ring.write([4, 5, 6])
        #expect(ring.read(from: &position, max: 100) == [4, 5, 6])
        #expect(ring.writeCount == 6)
    }

    @Test("A reader that falls behind gets the newest samples and skips the lost ones")
    func overrunSkipsToNewest() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 4)
        var position: UInt64 = 0
        ring.write([1, 2, 3, 4, 5, 6, 7])
        #expect(ring.read(from: &position, max: 100) == [4, 5, 6, 7])
        #expect(position == 7)
    }

    @Test("A single write larger than the buffer keeps only its newest samples")
    func oversizedWrite() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 3)
        ring.write([1, 2, 3, 4, 5])
        var position: UInt64 = 0
        #expect(ring.read(from: &position, max: 100) == [3, 4, 5])
        #expect(ring.writeCount == 5)
    }

    @Test("A read returns at most the requested number of samples")
    func readIsLimited() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 8)
        ring.write([1, 2, 3, 4, 5])
        var position: UInt64 = 0
        #expect(ring.read(from: &position, max: 2) == [1, 2])
        #expect(ring.read(from: &position, max: 2) == [3, 4])
        #expect(ring.read(from: &position, max: 2) == [5])
    }

    @Test("A reader position ahead of the writer is pulled back to the writer")
    func positionAheadOfWriter() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 8)
        ring.write([1, 2])
        var position: UInt64 = 50
        #expect(ring.read(from: &position, max: 100).isEmpty)
        #expect(position == 2)
    }

    @Test("Flags set through one handle are seen through another")
    func flagsAreShared() throws {
        let url = temporaryURL()
        let a = try AudioRing(url: url, capacity: 8)
        let b = try AudioRing(url: url, capacity: 8)
        a.isBroadcasting = true
        b.isCaptureWanted = true
        #expect(b.isBroadcasting)
        #expect(a.isCaptureWanted)
        a.isBroadcasting = false
        #expect(b.isBroadcasting == false)
    }

    @Test("Reopening an existing ring keeps its contents")
    func reopenKeepsContents() throws {
        let url = temporaryURL()
        do {
            let ring = try AudioRing(url: url, capacity: 8)
            ring.write([7, 8, 9])
        }
        let reopened = try AudioRing(url: url, capacity: 8)
        #expect(reopened.writeCount == 3)
        var position: UInt64 = 0
        #expect(reopened.read(from: &position, max: 100) == [7, 8, 9])
    }

    @Test("A file that is not a ring is replaced by an empty ring")
    func garbageFileIsReplaced() throws {
        let url = temporaryURL()
        try Data(repeating: 0xAB, count: 37).write(to: url)
        let ring = try AudioRing(url: url, capacity: 8)
        #expect(ring.writeCount == 0)
        ring.write([1])
        var position: UInt64 = 0
        #expect(ring.read(from: &position, max: 100) == [1])
    }

    @Test("A ring with a different capacity is replaced by an empty ring")
    func capacityMismatchIsReplaced() throws {
        let url = temporaryURL()
        do {
            let ring = try AudioRing(url: url, capacity: 8)
            ring.write([1, 2, 3])
        }
        let ring = try AudioRing(url: url, capacity: 16)
        #expect(ring.writeCount == 0)
    }

    @Test("Writing records the time of the write")
    func writeRecordsTime() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 8)
        #expect(ring.lastWriteTime == 0)
        ring.write([1], at: 1234.5)
        #expect(ring.lastWriteTime == 1234.5)
    }
}

@Suite("AudioRing sharing")
struct AudioRingSharingTests {
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("audio-ring-\(UUID().uuidString).bin")
    }

    @Test("Writing counts as a sign of life from the writer")
    func writeIsAHeartbeat() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 8)
        ring.write([1], at: 50)
        #expect(ring.lastHeartbeatTime == 50)
    }

    @Test("A heartbeat without audio does not count as a write")
    func heartbeatAlone() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 8)
        ring.write([1], at: 50)
        ring.heartbeat(at: 60)
        #expect(ring.lastHeartbeatTime == 60)
        #expect(ring.lastWriteTime == 50)
        #expect(ring.writeCount == 1)
    }

    @Test("A non-blocking write succeeds when nobody holds the ring")
    func tryWriteWhenFree() throws {
        let ring = try AudioRing(url: temporaryURL(), capacity: 8)
        let written = [1, 2, 3].withUnsafeBufferPointer { ring.tryWrite($0, at: 1) }
        #expect(written)
        var position: UInt64 = 0
        #expect(ring.read(from: &position, max: 100) == [1, 2, 3])
    }

    @Test("Opening a second handle while the first is in use does not clear it")
    func secondOpenKeepsData() throws {
        let url = temporaryURL()
        let first = try AudioRing(url: url, capacity: 8)
        first.write([1, 2, 3])
        first.isBroadcasting = true
        let second = try AudioRing(url: url, capacity: 8)
        #expect(second.writeCount == 3)
        #expect(first.isBroadcasting)
    }

    @Test("Replacing a ring of another capacity leaves the old handle usable")
    func replacingDoesNotBreakOldHandle() throws {
        let url = temporaryURL()
        let old = try AudioRing(url: url, capacity: 64)
        old.write([Int16](repeating: 7, count: 64))
        _ = try AudioRing(url: url, capacity: 8)
        // The old handle keeps its own mapping; touching all of it must not fault.
        var position: UInt64 = 0
        #expect(old.read(from: &position, max: 100).count == 64)
        old.write([Int16](repeating: 9, count: 64))
    }

    @Test("A reader never sees samples out of order while a writer is writing")
    func concurrentReadsStayContiguous() async throws {
        let url = temporaryURL()
        let capacity = 64
        let total = 20_000
        let writer = Task.detached {
            let ring = try AudioRing(url: url, capacity: capacity)
            var next: Int16 = 0
            var written = 0
            while written < total {
                let count = min(7, total - written)
                let chunk = (0..<count).map { _ -> Int16 in
                    defer { next = next == 9_999 ? 0 : next + 1 }
                    return next
                }
                ring.write(chunk)
                written += count
            }
        }
        let reader = Task.detached { () -> Bool in
            let ring = try AudioRing(url: url, capacity: capacity)
            var position: UInt64 = 0
            var contiguous = true
            while position < UInt64(total) {
                let before = position
                let samples = ring.read(from: &position, max: 50)
                // Every sample must be the one its position says: value == index mod 10000.
                let start = position - UInt64(samples.count)
                for (offset, sample) in samples.enumerated()
                where Int(sample) != Int((start + UInt64(offset)) % 10_000) {
                    contiguous = false
                }
                if samples.isEmpty, position == before { await Task.yield() }
            }
            return contiguous
        }
        try await writer.value
        #expect(try await reader.value)
    }
}

@Suite("AudioAvailability")
struct AudioAvailabilityTests {
    @Test("No broadcast flag means no broadcast")
    func notBroadcasting() {
        #expect(AudioAvailability.assess(isBroadcasting: false, lastHeartbeat: 100, lastWrite: 100, now: 100) == .notBroadcasting)
    }

    @Test("Fresh audio means receiving")
    func receiving() {
        #expect(AudioAvailability.assess(isBroadcasting: true, lastHeartbeat: 100, lastWrite: 99.5, now: 100) == .receiving)
    }

    @Test("A live broadcast with no recent audio is stalled")
    func stalled() {
        #expect(AudioAvailability.assess(isBroadcasting: true, lastHeartbeat: 99, lastWrite: 90, now: 100) == .stalled)
    }

    @Test("A broadcast flag left behind by a dead extension does not count as a broadcast")
    func staleFlag() {
        #expect(AudioAvailability.assess(isBroadcasting: true, lastHeartbeat: 80, lastWrite: 80, now: 100) == .notBroadcasting)
    }

    @Test("The thresholds are a second and a half for audio and five seconds for life")
    func thresholds() {
        #expect(AudioAvailability.assess(isBroadcasting: true, lastHeartbeat: 100, lastWrite: 98.6, now: 100) == .receiving)
        #expect(AudioAvailability.assess(isBroadcasting: true, lastHeartbeat: 100, lastWrite: 98.4, now: 100) == .stalled)
        #expect(AudioAvailability.assess(isBroadcasting: true, lastHeartbeat: 95.1, lastWrite: 0, now: 100) == .stalled)
        #expect(AudioAvailability.assess(isBroadcasting: true, lastHeartbeat: 94.9, lastWrite: 0, now: 100) == .notBroadcasting)
    }
}

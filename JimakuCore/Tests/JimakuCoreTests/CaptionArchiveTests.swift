import Foundation
import JimakuCore
import Testing

@Suite("CaptionArchive")
struct CaptionArchiveTests {
    private func session(_ number: Int, lines: Int = 1) -> SavedSession {
        SavedSession(
            id: UUID(),
            startedAt: Date(timeIntervalSince1970: Double(number) * 1000),
            spoken: "en",
            target: "zh-Hans",
            lines: (0..<lines).map { SavedSession.Line(original: "line \($0) of \(number)", translation: "第 \(number) 次的第 \($0) 句") }
        )
    }

    @Test("Sessions are listed newest first, whatever order they were kept in")
    func newestFirst() {
        var archive = CaptionArchive()
        let first = session(1), second = session(2), third = session(3)
        archive.keep(second)
        archive.keep(third)
        archive.keep(first)
        #expect(archive.sessions.map(\.id) == [third.id, second.id, first.id])
    }

    @Test("A session kept again, with more lines, takes the place of what was kept of it")
    func keptAgain() {
        var archive = CaptionArchive()
        var growing = session(1)
        archive.keep(growing)
        growing.lines.append(SavedSession.Line(original: "more", translation: nil))
        let dropped = archive.keep(growing)
        #expect(dropped.isEmpty)
        #expect(archive.sessions == [growing])
    }

    @Test("The thirty-first session drops the oldest, and keeping says which")
    func limit() {
        var archive = CaptionArchive()
        let all = (1...31).map { session($0) }
        var dropped: [UUID] = []
        for one in all { dropped += archive.keep(one) }
        #expect(archive.sessions.count == 30)
        #expect(dropped == [all[0].id])
        #expect(!archive.sessions.contains(all[0]))
        #expect(archive.sessions.first == all[30])
    }

    @Test("A session in which nothing was said is not kept")
    func nothingSaid() {
        var archive = CaptionArchive()
        #expect(archive.keep(session(1, lines: 0)).isEmpty)
        #expect(archive.sessions.isEmpty)
    }

    @Test("Made from what a device holds, the archive is newest first and says what is over the limit")
    func loaded() {
        let all = (1...33).map { session($0) }.shuffled()
        let (archive, over) = CaptionArchive.loaded(all)
        #expect(archive.sessions.count == 30)
        #expect(archive.sessions.first?.startedAt == Date(timeIntervalSince1970: 33_000))
        #expect(archive.sessions.last?.startedAt == Date(timeIntervalSince1970: 4000))
        #expect(Set(over) == Set(all.filter { $0.startedAt < Date(timeIntervalSince1970: 4000) }.map(\.id)))
    }

    @Test("Sessions that started at the same instant keep one order, whichever was kept first")
    func sameInstant() {
        let one = session(1), other = session(1)
        var forwards = CaptionArchive()
        forwards.keep(one)
        forwards.keep(other)
        var backwards = CaptionArchive()
        backwards.keep(other)
        backwards.keep(one)
        #expect(forwards.sessions.map(\.id) == backwards.sessions.map(\.id))
        #expect(CaptionArchive.loaded([one, other]).archive.sessions.map(\.id) == forwards.sessions.map(\.id))
    }

    @Test("One session can be removed, and all of them")
    func removing() {
        var archive = CaptionArchive()
        let first = session(1), second = session(2)
        archive.keep(first)
        archive.keep(second)
        archive.remove(first.id)
        #expect(archive.sessions == [second])
        archive.keep(first)
        #expect(Set(archive.removeAll()) == [first.id, second.id])
        #expect(archive.sessions.isEmpty)
    }
}

@Suite("SavedSession")
struct SavedSessionTests {
    @Test("As text, each line is its original, then its translation, then an empty line")
    func text() {
        let session = SavedSession(
            id: UUID(), startedAt: Date(timeIntervalSince1970: 0), spoken: "en", target: "zh-Hans",
            lines: [
                SavedSession.Line(original: "Good morning.", translation: "早上好。"),
                SavedSession.Line(original: "Not translated yet.", translation: nil),
                SavedSession.Line(original: "See you.", translation: "再见。"),
            ])
        #expect(session.text == "Good morning.\n早上好。\n\nNot translated yet.\n\nSee you.\n再见。\n")
    }

    @Test("The exported file is named after the app and when the session started, with no character a file name cannot hold")
    func fileName() {
        let session = SavedSession(
            id: UUID(), startedAt: Date(timeIntervalSince1970: 1_795_576_320), spoken: "en", target: "zh-Hans", lines: [])
        let name = session.fileName(in: TimeZone(identifier: "UTC")!)
        #expect(name == "Jimaku 2026-11-25 0312.txt")
        #expect(!name.contains(":") && !name.contains("/"))
    }

    @Test("A session written out and read back is the same session")
    func roundTrip() throws {
        let session = SavedSession(
            id: UUID(), startedAt: Date(timeIntervalSince1970: 1_795_576_320.5), spoken: "ja", target: "en",
            lines: [SavedSession.Line(original: "こんにちは。", translation: "Hello."), SavedSession.Line(original: "…", translation: nil)])
        let read = try SavedSession(data: session.data())
        #expect(read == session)
    }

    @Test("What is not a saved session is refused, not read as an empty one")
    func notASession() {
        #expect(throws: (any Error).self) { try SavedSession(data: Data("not json".utf8)) }
    }
}

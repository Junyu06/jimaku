import Foundation

/// The captions of one session, as they are kept on the device after it.
public struct SavedSession: Codable, Equatable, Sendable, Identifiable {
    /// One kept piece of speech and its translation, if it got one.
    public struct Line: Codable, Equatable, Sendable {
        public var original: String
        public var translation: String?

        public init(original: String, translation: String?) {
            self.original = original
            self.translation = translation
        }
    }

    public let id: UUID
    public var startedAt: Date
    /// The identifiers of the languages the session ran with.
    public var spoken: String
    public var target: String
    /// Oldest first.
    public var lines: [Line]

    public init(id: UUID, startedAt: Date, spoken: String, target: String, lines: [Line]) {
        self.id = id
        self.startedAt = startedAt
        self.spoken = spoken
        self.target = target
        self.lines = lines
    }

    /// The session as plain text: each line's original, then its translation,
    /// then an empty line.
    public var text: String {
        lines.map { line in
            [line.original, line.translation].compactMap { $0 }.joined(separator: "\n") + "\n"
        }.joined(separator: "\n")
    }

    /// A name for the session as a text file: the app's name and when the
    /// session started, to the minute, with nothing a file name cannot hold.
    public func fileName(in timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startedAt)
        return String(
            format: "Jimaku %04d-%02d-%02d %02d%02d.txt",
            parts.year ?? 0, parts.month ?? 0, parts.day ?? 0, parts.hour ?? 0, parts.minute ?? 0)
    }
}

extension SavedSession {
    /// The session as it is written to a file.
    public func data() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    /// Reads what `data()` wrote. Anything else is an error: a file that cannot
    /// be read is not taken for a session in which nothing was said.
    public init(data: Data) throws {
        self = try JSONDecoder().decode(SavedSession.self, from: data)
    }
}

/// The sessions kept on the device: the newest thirty.
public struct CaptionArchive: Equatable, Sendable {
    public static let limit = 30

    /// Newest first.
    public private(set) var sessions: [SavedSession] = []

    public init() {}

    /// The archive of what a device holds, and the sessions it holds over the
    /// limit, which are to be deleted.
    public static func loaded(_ held: [SavedSession]) -> (archive: CaptionArchive, over: [UUID]) {
        var archive = CaptionArchive()
        archive.sessions = held.sorted(by: comesBefore)
        let over = archive.trim()
        return (archive, over)
    }

    /// Keeps a session, in place of what was kept of it before. A session in
    /// which nothing was said is not kept. Returns the sessions that left
    /// because the archive was full.
    @discardableResult
    public mutating func keep(_ session: SavedSession) -> [UUID] {
        guard !session.lines.isEmpty else { return [] }
        sessions.removeAll { $0.id == session.id }
        let place = sessions.firstIndex { Self.comesBefore(session, $0) } ?? sessions.endIndex
        sessions.insert(session, at: place)
        return trim()
    }

    public mutating func remove(_ id: UUID) {
        sessions.removeAll { $0.id == id }
    }

    /// Empties the archive. Returns what was in it.
    @discardableResult
    public mutating func removeAll() -> [UUID] {
        let all = sessions.map(\.id)
        sessions = []
        return all
    }

    /// Newest first; sessions that started at the same instant go by their
    /// identifiers, so the order does not depend on which was kept first.
    private static func comesBefore(_ one: SavedSession, _ other: SavedSession) -> Bool {
        if one.startedAt != other.startedAt { return one.startedAt > other.startedAt }
        return one.id.uuidString < other.id.uuidString
    }

    private mutating func trim() -> [UUID] {
        guard sessions.count > Self.limit else { return [] }
        let over = sessions[Self.limit...].map(\.id)
        sessions.removeSubrange(Self.limit...)
        return over
    }
}

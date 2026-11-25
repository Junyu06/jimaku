import CoreTransferable
import Foundation
import JimakuCore
import os
import UniformTypeIdentifiers

/// Reads and writes the saved sessions: one file each, in a folder of the
/// app's own on this device. The folder is left out of the device's backups,
/// so what was watched does not leave the device with them.
struct SavedSessionStore {
    private let folder: URL
    private let log = Logger(subsystem: "Jimaku", category: "saved")

    init() {
        folder = URL.applicationSupportDirectory.appending(path: "SavedSessions", directoryHint: .isDirectory)
    }

    /// Every session the folder holds. A file that cannot be read, or that
    /// holds a session other than the one it is named after, is skipped and
    /// left where it is.
    func readAll() -> [SavedSession] {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "json" }.compactMap { file in
            do {
                let session = try SavedSession(data: Data(contentsOf: file))
                guard self.file(for: session.id).lastPathComponent == file.lastPathComponent else {
                    log.error("a saved file holds a session it is not named after")
                    return nil
                }
                return session
            } catch {
                log.error("could not read a saved session: \(String(describing: error))")
                return nil
            }
        }
    }

    /// Writes a session over what was written of it before, and says whether
    /// it is on the device now. Readable while the device is locked: a session
    /// goes on then.
    func write(_ session: SavedSession) -> Bool {
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var folder = folder
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try folder.setResourceValues(values)
            try session.data().write(
                to: file(for: session.id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch {
            log.error("could not write a session: \(String(describing: error))")
            return false
        }
    }

    /// Deletes a session and any text file made of it for sharing, and says
    /// whether the session is gone from the device. A text file that could
    /// not be removed does not keep the session listed, where the next save
    /// would write it again; such files are removed when the app next starts.
    func delete(_ id: UUID) -> Bool {
        let export = Self.exportFolder(for: id)
        let file = file(for: id)
        try? FileManager.default.removeItem(at: export)
        // The folder of all such copies goes with its last one.
        if let left = try? FileManager.default.contentsOfDirectory(atPath: Self.exportsFolder.path), left.isEmpty {
            try? FileManager.default.removeItem(at: Self.exportsFolder)
        }
        try? FileManager.default.removeItem(at: file)
        if FileManager.default.fileExists(atPath: export.path) {
            log.error("could not delete the text file made of a session")
        }
        let gone = !FileManager.default.fileExists(atPath: file.path)
        if !gone { log.error("could not delete a session") }
        return gone
    }

    /// Deletes everything kept of saved sessions: the folder itself, with the
    /// files that could not be read and the ones no longer listed, and every
    /// text file made for sharing. Says whether nothing is left. The folder
    /// is made again at the next write.
    func deleteEverything() -> Bool {
        clearExports()
        try? FileManager.default.removeItem(at: folder)
        let clean = !FileManager.default.fileExists(atPath: folder.path)
            && !FileManager.default.fileExists(atPath: Self.exportsFolder.path)
        if !clean { log.error("could not delete every saved session") }
        return clean
    }

    /// Whether the device holds any saved session or text file made of one,
    /// readable or not. A folder that is there and cannot be listed counts
    /// as holding something.
    var holdsAnything: Bool {
        let manager = FileManager.default
        if manager.fileExists(atPath: Self.exportsFolder.path) { return true }
        guard manager.fileExists(atPath: folder.path) else { return false }
        guard let files = try? manager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {
            return true
        }
        return !files.isEmpty
    }

    /// Removes every text file made for sharing. They are copies of captions
    /// and are not kept from one run of the app to the next.
    func clearExports() {
        try? FileManager.default.removeItem(at: Self.exportsFolder)
    }

    private func file(for id: UUID) -> URL {
        folder.appending(path: "\(id.uuidString).json")
    }

    private static let exportsFolder = FileManager.default.temporaryDirectory
        .appending(path: "Export", directoryHint: .isDirectory)

    /// Where the text file of one session is put for sharing: a folder of its
    /// own, so two sessions that started in the same minute keep two files.
    fileprivate static func exportFolder(for id: UUID) -> URL {
        exportsFolder.appending(path: id.uuidString, directoryHint: .isDirectory)
    }
}

/// A saved session as the system's share sheet takes it: a plain-text file,
/// written only when the sheet asks for it.
struct SavedSessionText: Transferable {
    let session: SavedSession

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { text in
            let folder = SavedSessionStore.exportFolder(for: text.session.id)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let file = folder.appending(path: text.session.fileName())
            try Data(text.session.text.utf8).write(
                to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return SentTransferredFile(file)
        }
    }
}

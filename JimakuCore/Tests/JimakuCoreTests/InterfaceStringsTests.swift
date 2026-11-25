import Foundation
import Testing

/// The interface is written in Chinese in the source and has an English
/// version in the string catalogs. These tests read the source and the
/// catalogs of the app and the broadcast extension, which have no test target
/// of their own.
@Suite("Interface strings")
struct InterfaceStringsTests {
    /// The repository, found from this file.
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()

    /// Files whose Chinese literals are plain strings, not SwiftUI text: there
    /// a literal is looked up only when the code asks for it.
    private static let plainStringFiles = [
        "JimakuApp/SessionController.swift", "JimakuApp/AppleIntelligenceTranslator.swift",
        "JimakuApp/SpeechRecognition.swift", "JimakuApp/Translation.swift", "JimakuApp/BroadcastPicker.swift",
        "JimakuBroadcast/SampleHandler.swift",
    ]

    @Test("Every Chinese string in the app's source has an English translation with the same placeholders")
    func appStringsAreTranslated() throws {
        try expectTranslated(directory: "JimakuApp")
    }

    @Test("Every Chinese string in the broadcast extension's source has an English translation with the same placeholders")
    func extensionStringsAreTranslated() throws {
        try expectTranslated(directory: "JimakuBroadcast")
    }

    @Test("Where a Chinese string is a plain string, the code asks for its translation")
    func plainStringsAreLookedUp() throws {
        for file in Self.plainStringFiles {
            let source = try String(contentsOf: Self.root.appendingPathComponent(file), encoding: .utf8)
            for literal in Self.literals(in: source) where Self.hasChinese(literal.text) {
                let asked = literal.before.hasSuffix("String(localized: ") || literal.before.hasSuffix("defaultValue: ")
                #expect(asked, "\(file): \(literal.text) is shown as written, in every language")
            }
        }
    }

    @Test("A text the code asks for by a name of its own is in the catalog under that name")
    func namedKeysExist() throws {
        for directory in ["JimakuApp", "JimakuBroadcast"] {
            let catalog = try Self.catalog(at: "\(directory)/Localizable.xcstrings")
            for file in try Self.swiftFiles(in: directory) {
                let source = try String(contentsOf: file, encoding: .utf8)
                for literal in Self.literals(in: source) where literal.before.hasSuffix("String(localized: ") {
                    #expect(catalog[literal.key] != nil, "\(file.lastPathComponent): \(literal.key) is not in the catalog")
                }
            }
        }
    }

    @Test("Every entry of the catalogs has both languages")
    func catalogsHaveBothLanguages() throws {
        for path in ["JimakuApp/Localizable.xcstrings", "JimakuApp/InfoPlist.xcstrings", "JimakuBroadcast/Localizable.xcstrings"] {
            let catalog = try Self.catalog(at: path)
            #expect(!catalog.isEmpty, "\(path) has no entries")
            for (key, values) in catalog {
                #expect(values["en"]?.isEmpty == false, "\(path): \(key) has no English")
                #expect(values["zh-Hans"]?.isEmpty == false, "\(path): \(key) has no Chinese")
            }
        }
    }

    // MARK: Reading

    private func expectTranslated(directory: String) throws {
        let catalog = try Self.catalog(at: "\(directory)/Localizable.xcstrings")
        let files = try Self.swiftFiles(in: directory)
        #expect(!files.isEmpty)
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            for literal in Self.literals(in: source) where Self.hasChinese(literal.text) {
                // A text given as the default of a named key is looked up by
                // that name; the catalog test covers it.
                if literal.before.hasSuffix("defaultValue: ") { continue }
                let key = literal.key
                guard let english = catalog[key]?["en"] else {
                    Issue.record("\(file.lastPathComponent): \(key) is not in the catalog")
                    continue
                }
                #expect(!Self.hasChinese(english), "\(key) has Chinese in its English")
                #expect(
                    Self.placeholders(in: english) == Self.placeholders(in: key),
                    "\(key) and its English take different numbers of values")
                #expect(Self.numbersAreDistinct(in: english), "\(key) names one value twice in its English")
            }
        }
    }

    /// The Swift files directly in one of the repository's folders.
    private static func swiftFiles(in directory: String) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: root.appendingPathComponent(directory), includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "swift" }
    }

    /// The entries of a string catalog: key, then language, then text.
    private static func catalog(at path: String) throws -> [String: [String: String]] {
        let data = try Data(contentsOf: root.appendingPathComponent(path))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = json?["strings"] as? [String: [String: Any]] ?? [:]
        return strings.mapValues { entry in
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            return localizations.compactMapValues { ($0["stringUnit"] as? [String: Any])?["value"] as? String }
        }
    }

    private struct Literal {
        /// The text between the quotes, as written.
        var text: String
        /// The key the system looks it up by: each interpolation is a `%@`.
        var key: String
        /// What stands on the line before the opening quote.
        var before: String
    }

    /// The string literals of a source file, leaving out comments. Enough for
    /// the literals this app has: one line each, interpolations without quotes
    /// inside them.
    private static func literals(in source: String) -> [Literal] {
        var found: [Literal] = []
        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let characters = Array(line)
            var index = 0
            while index < characters.count {
                if characters[index] == "/", index + 1 < characters.count, characters[index + 1] == "/" { break }
                guard characters[index] == "\"" else {
                    index += 1
                    continue
                }
                let start = index
                index += 1
                var text = ""
                var key = ""
                while index < characters.count, characters[index] != "\"" {
                    if characters[index] == "\\", index + 1 < characters.count {
                        if characters[index + 1] == "(" {
                            // An interpolation: skip to its closing parenthesis.
                            var depth = 0
                            var inside = "\\"
                            index += 1
                            repeat {
                                if characters[index] == "(" { depth += 1 }
                                if characters[index] == ")" { depth -= 1 }
                                inside.append(characters[index])
                                index += 1
                            } while index < characters.count && depth > 0
                            text += inside
                            key += "%@"
                        } else {
                            text.append(characters[index])
                            text.append(characters[index + 1])
                            key.append(characters[index + 1])
                            index += 2
                        }
                    } else {
                        text.append(characters[index])
                        key.append(characters[index])
                        index += 1
                    }
                }
                index += 1
                found.append(Literal(text: text, key: key, before: String(characters[..<start])))
            }
        }
        return found
    }

    private static func hasChinese(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) }
    }

    /// False when a format names the same value twice, as `%1$@ … %1$@`.
    private static func numbersAreDistinct(in format: String) -> Bool {
        var seen: Set<Substring> = []
        var rest = Substring(format)
        while let percent = rest.firstIndex(of: "%") {
            let start = rest.index(after: percent)
            var end = start
            while end < rest.endIndex, rest[end].isNumber { end = rest.index(after: end) }
            if end > start, end < rest.endIndex, rest[end] == "$" {
                if !seen.insert(rest[start..<end]).inserted { return false }
            }
            rest = rest[end...]
        }
        return true
    }

    /// How many values a format takes: `%@` and `%1$@` each count once.
    private static func placeholders(in format: String) -> Int {
        var count = 0
        var rest = Substring(format)
        while let percent = rest.firstIndex(of: "%") {
            var end = rest.index(after: percent)
            while end < rest.endIndex, rest[end].isNumber || rest[end] == "$" { end = rest.index(after: end) }
            if end < rest.endIndex, rest[end] == "@" { count += 1 }
            rest = rest[end...]
        }
        return count
    }
}

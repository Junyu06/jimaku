import JimakuCore
import Testing

@MainActor
@Suite("TranslationsAhead")
struct TranslationsAheadTests {
    private struct Failure: Error {}

    /// Counts the calls and lets a test decide when each one returns.
    @MainActor
    private final class Translator {
        var calls: [String] = []
        var failing: Set<String> = []
        func translate(_ text: String) async throws -> String {
            calls.append(text)
            await Task.yield()
            if failing.contains(text) { throw Failure() }
            return "<\(text)>"
        }
    }

    @Test("A text asked for twice is translated once")
    func once() async throws {
        let translator = Translator()
        let ahead = TranslationsAhead()
        let first = ahead.translation(of: "one", by: translator.translate)
        let second = ahead.translation(of: "one", by: translator.translate)
        #expect(try await first.value == "<one>")
        #expect(try await second.value == "<one>")
        #expect(translator.calls == ["one"])
    }

    @Test("Translations run one at a time, in the order asked")
    func inOrder() async throws {
        let translator = Translator()
        let ahead = TranslationsAhead()
        let tasks = ["one", "two", "three"].map { ahead.translation(of: $0, by: translator.translate) }
        for task in tasks { _ = try await task.value }
        #expect(translator.calls == ["one", "two", "three"])
    }

    @Test("A translation that failed is forgotten, so asking again tries again")
    func failureIsForgotten() async throws {
        let translator = Translator()
        translator.failing = ["one"]
        let ahead = TranslationsAhead()
        let failed = ahead.translation(of: "one", by: translator.translate)
        await #expect(throws: Failure.self) { try await failed.value }
        translator.failing = []
        #expect(try await ahead.translation(of: "one", by: translator.translate).value == "<one>")
        #expect(translator.calls == ["one", "one"])
    }

    @Test("After a reset nothing asked for before is kept, and what had not started is not translated")
    func reset() async throws {
        let translator = Translator()
        let ahead = TranslationsAhead()
        let first = ahead.translation(of: "one", by: translator.translate)
        let second = ahead.translation(of: "two", by: translator.translate)
        ahead.reset()
        _ = await first.result
        await #expect(throws: CancellationError.self) { try await second.value }
        #expect(!translator.calls.contains("two"))
        // With another translator, the same text is translated anew.
        let other = Translator()
        #expect(try await ahead.translation(of: "one", by: other.translate).value == "<one>")
        #expect(other.calls == ["one"])
    }

    @Test("Only so many are kept: the oldest is dropped, and not translated if it had not started")
    func limit() async throws {
        let translator = Translator()
        let ahead = TranslationsAhead(limit: 2)
        let first = ahead.translation(of: "one", by: translator.translate)
        let second = ahead.translation(of: "two", by: translator.translate)
        let third = ahead.translation(of: "three", by: translator.translate)
        _ = await first.result
        _ = try await second.value
        #expect(try await third.value == "<three>")
        // "one" was dropped when "three" was asked for, so it is asked for anew.
        _ = try await ahead.translation(of: "one", by: translator.translate).value
        #expect(translator.calls.filter { $0 == "two" }.count == 1)
        #expect(translator.calls.last == "one")
    }

    @Test("Forgetting a text makes the next request for it translate again")
    func forget() async throws {
        let translator = Translator()
        let ahead = TranslationsAhead()
        _ = try await ahead.translation(of: "one", by: translator.translate).value
        ahead.forget("one")
        _ = try await ahead.translation(of: "one", by: translator.translate).value
        #expect(translator.calls == ["one", "one"])
    }

    /// A translator whose calls return only when the test lets them, and which
    /// tells the test when a call has begun.
    @MainActor
    private final class Gate {
        var running = 0
        var most = 0
        var started: [String] = []
        private var calls: [String: CheckedContinuation<Void, Error>] = [:]
        private var watchers: [String: [CheckedContinuation<Void, Never>]] = [:]

        func translate(_ text: String) async throws -> String {
            running += 1
            most = max(most, running)
            defer { running -= 1 }
            try await withCheckedThrowingContinuation { (call: CheckedContinuation<Void, Error>) in
                calls[text] = call
                started.append(text)
                watchers.removeValue(forKey: text)?.forEach { $0.resume() }
            }
            return "<\(text)>"
        }

        /// Returns once the call for `text` has begun and is waiting.
        func begun(_ text: String) async {
            guard !started.contains(text) else { return }
            await withCheckedContinuation { watchers[text, default: []].append($0) }
        }

        func finish(_ text: String) {
            calls.removeValue(forKey: text)?.resume()
        }

        func fail(_ text: String) {
            calls.removeValue(forKey: text)?.resume(throwing: Failure())
        }
    }

    @Test("A second translation does not start while the first is running", .timeLimit(.minutes(1)))
    func neverTwoAtOnce() async throws {
        let gate = Gate()
        let ahead = TranslationsAhead()
        let first = ahead.translation(of: "one", by: gate.translate)
        let second = ahead.translation(of: "two", by: gate.translate)
        await gate.begun("one")
        #expect(gate.started == ["one"])
        gate.finish("one")
        await gate.begun("two")
        gate.finish("two")
        #expect(try await first.value == "<one>")
        #expect(try await second.value == "<two>")
        #expect(gate.most == 1)
    }

    @Test(
        "After a reset, a new translator does not wait for a call of the old one that has not returned",
        .timeLimit(.minutes(1)))
    func resetDoesNotWaitForTheOld() async throws {
        let old = Gate()
        let ahead = TranslationsAhead()
        _ = ahead.translation(of: "one", by: old.translate)
        await old.begun("one")
        ahead.reset()
        let new = Translator()
        #expect(try await ahead.translation(of: "two", by: new.translate).value == "<two>")
        old.finish("one")
    }

    @Test("A late failure of an old request does not remove a new request for the same text", .timeLimit(.minutes(1)))
    func oldFailureLeavesTheNewRequest() async throws {
        let old = Gate()
        let ahead = TranslationsAhead()
        let failing = ahead.translation(of: "one", by: old.translate)
        await old.begun("one")
        // The translator is changed while the old call is running.
        ahead.reset()
        let fresh = Translator()
        let again = ahead.translation(of: "one", by: fresh.translate)
        old.fail("one")
        await #expect(throws: Failure.self) { try await failing.value }
        // Still the same new request: asking again does not translate again.
        let same = ahead.translation(of: "one", by: fresh.translate)
        #expect(try await again.value == "<one>")
        #expect(try await same.value == "<one>")
        #expect(fresh.calls == ["one"])
    }
}

/// Translations asked for, by the text they translate, so that a text asked
/// for twice is translated once.
///
/// Speech the recognizer has finalized on a short quiet is translated ahead of
/// time, before it is known whether the speaker stopped. If they did, the
/// translation is here, done or under way, when the caption asks for it.
///
/// One translation runs at a time, in the order asked. A translation that
/// fails is forgotten, so asking again tries again.
@MainActor
public final class TranslationsAhead {
    public typealias Translate = @MainActor (String) async throws -> String

    private struct Request {
        let id: Int
        let task: Task<String, Error>
    }

    private var requests: [String: Request] = [:]
    /// The texts asked for, oldest first.
    private var order: [String] = []
    private var last: Task<Void, Never>?
    private var nextID = 0
    private let limit: Int

    /// - Parameter limit: how many translations are kept. Asking for more
    ///   drops the oldest.
    public init(limit: Int = 12) {
        self.limit = max(limit, 1)
    }

    /// The translation of `text`, started now unless it was asked for before.
    public func translation(of text: String, by translate: @escaping Translate) -> Task<String, Error> {
        if let request = requests[text] { return request.task }
        let previous = last
        let id = nextID
        nextID += 1
        let task = Task { [weak self] in
            await previous?.value
            do {
                // Dropped before its turn came: not worth translating.
                try Task.checkCancellation()
                return try await translate(text)
            } catch {
                self?.drop(text, id: id)
                throw error
            }
        }
        last = Task { _ = await task.result }
        requests[text] = Request(id: id, task: task)
        order.append(text)
        while order.count > limit { forget(order[0]) }
        return task
    }

    /// Forgets a translation, so that asking again translates again. If it has
    /// not started yet, it is not made.
    public func forget(_ text: String) {
        requests[text]?.task.cancel()
        requests[text] = nil
        order.removeAll { $0 == text }
    }

    /// Forgets everything, for a new translator or a new session. Translations
    /// that have not started are not made, and what is asked for next does not
    /// wait for one that is still running.
    public func reset() {
        requests.values.forEach { $0.task.cancel() }
        requests = [:]
        order = []
        last = nil
    }

    /// Removes a request that failed, unless the text has been asked for anew
    /// since.
    private func drop(_ text: String, id: Int) {
        guard requests[text]?.id == id else { return }
        requests[text] = nil
        order.removeAll { $0 == text }
    }
}

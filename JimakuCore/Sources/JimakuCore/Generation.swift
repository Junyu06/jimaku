/// Tells a current asynchronous result from a stale one.
///
/// Starting recognition or preparing translation takes time. If the session is
/// stopped, restarted, or reconfigured meanwhile, the old work may still finish
/// later. Whoever starts such work takes a token; when the work finishes, its result
/// is used only if the token is still current.
public struct Generation: Equatable, Sendable {
    public struct Token: Equatable, Sendable {
        fileprivate let value: Int
    }

    private var value = 0

    public init() {}

    /// Issues a new token. Every token issued earlier becomes stale.
    public mutating func advance() -> Token {
        value += 1
        return Token(value: value)
    }

    /// Makes every issued token stale without issuing a new one.
    public mutating func invalidate() {
        value += 1
    }

    public func isCurrent(_ token: Token) -> Bool {
        token.value == value
    }
}

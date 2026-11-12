/// Scripted captions used to exercise the caption window before audio capture,
/// recognition, and translation exist.
public enum DemoCaptions {
    public static let script: [CaptionLines] = [
        CaptionLines(original: "This is a demo caption.", translation: "这是一条演示字幕。"),
        CaptionLines(original: "The window should stay on top.", translation: "这个窗口应该一直浮在最上面。"),
        CaptionLines(original: "これはテスト用の字幕です。", translation: "这是测试用的字幕。"),
        CaptionLines(original: "Switch to another app and keep watching.", translation: "切到别的 app，继续看。"),
    ]

    /// The caption to show at a given tick. Ticks wrap around the script; a negative
    /// tick is treated as tick 0.
    public static func lines(at tick: Int) -> CaptionLines {
        script[max(tick, 0) % script.count]
    }
}

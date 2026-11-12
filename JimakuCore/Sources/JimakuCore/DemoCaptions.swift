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

extension DemoCaptions {
    /// A short speech in `language`, sentence by sentence, with its translation.
    /// Stands in for a video where there is no speech recognition or translation.
    public static func speech(in language: SourceLanguage) -> [CaptionLines] {
        switch language {
        case .english:
            [
                CaptionLines(
                    original: "So yesterday I took the early train into the city, and it was completely packed.",
                    translation: "昨天我坐早班火车进城，车上挤得满满的。"
                ),
                CaptionLines(
                    original: "I ended up standing next to the door for almost an hour.",
                    translation: "结果我在车门边站了将近一个小时。"
                ),
                CaptionLines(
                    original:
                        "When I finally got to the office, the meeting had already started, so I just sat down in the back.",
                    translation: "等我终于到了办公室，会已经开始了，我就在后排坐下了。"
                ),
                CaptionLines(
                    original: "Honestly, I think I am going to leave ten minutes earlier from now on.",
                    translation: "说实话，我想以后还是早十分钟出门吧。"
                ),
            ]
        case .japanese:
            [
                CaptionLines(
                    original: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。",
                    translation: "今天从早上开始天气就特别好，所以我去附近的公园散了步。"
                ),
                CaptionLines(
                    original: "途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを二つ買いました。",
                    translation: "路上发现了一家新开的面包店，买了两个刚出炉的可颂。"
                ),
                CaptionLines(
                    original: "店員さんがとても親切で、おすすめのコーヒーも教えてくれました。",
                    translation: "店员特别热情，还给我推荐了咖啡。"
                ),
                CaptionLines(
                    original: "家に帰ってから食べてみたら、本当においしかったです。",
                    translation: "回家以后尝了一下，真的很好吃。"
                ),
                CaptionLines(
                    original: "また来週も行ってみようと思います。",
                    translation: "我打算下周再去一次。"
                ),
            ]
        }
    }

    /// A stand-in translation for a piece of `speech`: the share of each
    /// sentence's translation that matches the share of the sentence the piece
    /// covers. Nil when the piece is not part of the speech.
    public static func translation(of piece: String, in speech: [CaptionLines]) -> String? {
        func spoken(_ text: String) -> [Character] {
            Array(text.lowercased().filter(CaptionText.isSpoken))
        }
        let wanted = spoken(piece)
        let sentences = speech.map { spoken($0.original) }
        let all = sentences.flatMap { $0 }
        guard !wanted.isEmpty, wanted.count <= all.count,
            let start = (0...(all.count - wanted.count)).first(where: { Array(all[$0..<($0 + wanted.count)]) == wanted })
        else { return nil }
        let end = start + wanted.count

        var result = ""
        var offset = 0
        for (sentence, lines) in zip(sentences, speech) {
            defer { offset += sentence.count }
            let from = max(start, offset) - offset
            let to = min(end, offset + sentence.count) - offset
            guard from < to, !sentence.isEmpty else { continue }
            let translation = Array(lines.translation)
            let share = Double(translation.count) / Double(sentence.count)
            let first = Int((Double(from) * share).rounded())
            let last = to == sentence.count ? translation.count : Int((Double(to) * share).rounded())
            result += String(translation[first..<max(first, last)])
        }
        return result.isEmpty ? nil : result
    }
}

import JimakuCore

/// What the system speech recognizer reported, in order, for two short recordings:
/// synthetic speech played to the recognizer at normal speed on a Mac on 2026-11-12,
/// with the same settings the app uses. Times are seconds since the audio started.
/// Only the first and last guess of each burst are kept.
///
/// The recordings show the two behaviors the transcript has to cope with: guesses
/// arrive in bursts about a second apart, and punctuation inside text reported long
/// ago keeps appearing and disappearing while the words stay.
enum RecordedSpeech {
    struct Step: Sendable {
        let time: Double
        let isFinal: Bool
        let text: String

        var update: RecognitionUpdate { isFinal ? .final(text) : .partial(text) }
    }

    /// Continuous Japanese speech: about twenty seconds without a final result.
    static let japanese: [Step] = [
        Step(time: 1.10, isFinal: false, text: "今"),
        Step(time: 1.11, isFinal: false, text: "今日は朝"),
        Step(time: 2.02, isFinal: false, text: "今日は朝か"),
        Step(time: 2.04, isFinal: false, text: "今日は朝からとてもいい"),
        Step(time: 3.06, isFinal: false, text: "今日は朝からとてもいい天"),
        Step(time: 3.07, isFinal: false, text: "今日は朝からとてもいい天気だったので、"),
        Step(time: 4.12, isFinal: false, text: "今日は朝からとてもいい天気だったので、近"),
        Step(time: 4.13, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園ま"),
        Step(time: 5.06, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで"),
        Step(time: 5.07, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行っ"),
        Step(time: 6.10, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行って"),
        Step(time: 6.12, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途"),
        Step(time: 7.04, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中"),
        Step(time: 7.06, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しい"),
        Step(time: 8.09, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパ"),
        Step(time: 8.11, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけ"),
        Step(time: 9.12, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて"),
        Step(time: 9.13, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたての"),
        Step(time: 10.07, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたてのク"),
        Step(time: 10.08, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたてのクロワワッサンを"),
        Step(time: 11.12, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたてのクロロワッサンを 2"),
        Step(time: 11.13, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2ついました。"),
        Step(time: 12.07, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたてのクロワッサンを 2つ買いました。店"),
        Step(time: 12.08, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたてのクロワッサンを 2つ買いました。店員さんがとても"),
        Step(time: 13.12, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたてのクロワッサンを 2つ買いました。店員さんがとても親"),
        Step(time: 13.13, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でお"),
        Step(time: 14.18, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおす"),
        Step(time: 14.20, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒー"),
        Step(time: 15.12, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも"),
        Step(time: 15.13, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。"),
        Step(time: 16.19, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家"),
        Step(time: 16.20, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰って"),
        Step(time: 17.14, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってか"),
        Step(time: 17.15, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら"),
        Step(time: 18.18, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本"),
        Step(time: 18.19, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本当に美味し"),
        Step(time: 19.22, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本当に美味しか"),
        Step(time: 19.24, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本当に美味しかったです。また"),
        Step(time: 20.17, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本当に美味しかったです。また来"),
        Step(time: 20.18, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本当に美味しかったです。また来週も行"),
        Step(time: 21.23, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本当に美味しかったです。また来週も行っ"),
        Step(time: 21.25, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本当に美味しかったです。また来週も行ってみようと思います"),
        Step(time: 22.17, isFinal: false, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて、焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本当に美味しかったです。また来週も行ってみようと思います。"),
        Step(time: 22.29, isFinal: true, text: "今日は朝からとてもいい天気だったので、近くの公園まで散歩に行ってきました。途中で新しいパン屋さんを見つけて焼きたてのクロワッサンを 2つ買いました。店員さんがとても親切でおすすめのコーヒーも教えてくれました。家に帰ってから食べてみたら本当に美味しかったです。また来週も行ってみようと思います。"),
    ]

    /// English speech with pauses: a final result after each sentence or two.
    static let english: [Step] = [
        Step(time: 1.07, isFinal: false, text: "So"),
        Step(time: 1.07, isFinal: false, text: "So yesterday I"),
        Step(time: 2.00, isFinal: false, text: "So yesterday I took"),
        Step(time: 2.00, isFinal: false, text: "So yesterday I took the early train"),
        Step(time: 3.04, isFinal: false, text: "So yesterday I took the early train into"),
        Step(time: 3.05, isFinal: false, text: "So yesterday I took the early train into the city, and"),
        Step(time: 4.09, isFinal: false, text: "So yesterday I took the early train into the city, and it"),
        Step(time: 4.09, isFinal: false, text: "So yesterday I took the early train into the city, and it was completely"),
        Step(time: 5.03, isFinal: false, text: "So yesterday I took the early train into the city, and it was completely pack"),
        Step(time: 5.03, isFinal: false, text: "So yesterday I took the early train into the city, and it was completely packed."),
        Step(time: 5.14, isFinal: true, text: "So yesterday, I took the early train into the city, and it was completely packed."),
        Step(time: 5.14, isFinal: false, text: " I"),
        Step(time: 5.14, isFinal: false, text: " I ended"),
        Step(time: 6.07, isFinal: false, text: " I ended up"),
        Step(time: 6.07, isFinal: false, text: " I ended up standing next to the"),
        Step(time: 7.01, isFinal: false, text: " I ended up standing next to the door"),
        Step(time: 7.01, isFinal: false, text: " I ended up standing next to the door for almost an hour"),
        Step(time: 8.05, isFinal: false, text: " I ended up standing next to the door for almost an hour when"),
        Step(time: 8.05, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally"),
        Step(time: 9.10, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got"),
        Step(time: 9.11, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office"),
        Step(time: 10.05, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office,"),
        Step(time: 10.05, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had"),
        Step(time: 11.09, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already"),
        Step(time: 11.09, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started,"),
        Step(time: 12.03, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so"),
        Step(time: 12.03, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down"),
        Step(time: 13.07, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in"),
        Step(time: 13.08, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in the back, honest"),
        Step(time: 14.12, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in the back, honestly"),
        Step(time: 14.13, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in the back, honestly, I think I"),
        Step(time: 15.06, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in the back, honestly, I think I am"),
        Step(time: 15.07, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in the back, honestly, I think I am going to leave 10"),
        Step(time: 16.11, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in the back, honestly, I think I am going to leave 10 minutes"),
        Step(time: 16.11, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in the back, honestly, I think I am going to leave 10 minutes earlier from"),
        Step(time: 17.16, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in the back, honestly, I think I am going to leave 10 minutes earlier from now"),
        Step(time: 17.16, isFinal: false, text: " I ended up standing next to the door for almost an hour when I finally got to the office, the meeting had already started, so I just sat down in the back, honestly, I think I am going to leave 10 minutes earlier from now on."),
        Step(time: 17.36, isFinal: true, text: " I ended up standing next to the door for almost an hour, when I finally got to the office, the meeting had already started, so I just sat down in the back, honestly, I think I am going to leave 10 minutes earlier from now on."),
    ]
}

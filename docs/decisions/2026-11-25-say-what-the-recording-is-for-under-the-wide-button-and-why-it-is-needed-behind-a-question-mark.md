date: 2026-11-25
status: accepted
supersedes: in part 2026-11-23-lay-the-systems-broadcast-control-over-one-wide-button-while-no-broadcast-runs.md: the label under the wide button, and leaving what the button is for to the button and the system's sheet

# Say what the recording is for under the wide button, and why it is needed behind a question mark

Under the wide button 打开录屏 the page shows one small line, 用来听视频的声音 (for hearing the video's sound), with a question mark. A tap on it brings up a page of the app's own that says why the recording is needed.

The page has a title, 为什么要打开录屏, and three rows, each a few words in bold over one plain sentence:

- 拿到视频的声音: the app needs the recording to get the sound of the video, and captions come from that sound.
- 不保存任何画面: only the sound is used, and no picture is kept.
- 每次开始都要开一次: after each tap on Start the system's sheet 屏幕直播 comes up, and the user taps 开始直播 in it.

Why: the label this replaces, 只用声音，不保存画面, said what the recording does not do and not what it is for. The owner, seeing the page with it, asked why a recording should be opened at all, and pointed at what the system's own apps and the large chat apps do: where a control raises a question, they put a question mark or a second line there. The texts on the start page stay labels of a few words; sentences are on the page the user asks for.

The words of the three rows are the owner's choice among three versions. An earlier wording of the rows spoke from the system's side (that the system lets only a recording hear other apps) and headed the third row "how to open it"; the owner rejected it and asked for plain statements from the user's side: what we need the recording for, that we keep no picture, and when the user is asked to do it and where.

The second row says no picture is kept because the broadcast extension writes only the audio the system hands it and drops every other buffer; see `JimakuBroadcast/SampleHandler.swift`.

The line with the question mark is in a form row of its own; see `docs/pitfalls/a-tap-on-the-broadcast-control-also-presses-another-button-in-the-same-form-row.md`.

Rejected: a longer label under the button. The owner had already said that sentences are not what the text of an interface looks like.

Rejected: a title on the line with the question mark that repeats the question (为什么要打开录屏) in place of the reason. The reason in a few words can be read without a tap.

Not decided here: an entry to the page from anywhere else. While a recording runs the page has no line that opens it. When the page comes by itself is in `docs/decisions/2026-11-25-show-the-page-that-says-why-the-recording-is-needed-once-before-the-first-session.md`.

Status of evidence: the line and the page were looked at in an iPad simulator; see `docs/cases/audio-004-a-session-with-no-broadcast-shows-the-wide-button-and-under-it-what-the-recording-is-for.md` and `docs/cases/audio-010-the-question-mark-under-the-wide-button-brings-up-the-page-that-says-why-the-recording-is-needed.md`. Nothing of this has run on a device, and the page has not been looked at on an iPhone, where a sheet takes the whole height. The name 屏幕直播 for the system's sheet is written from memory of the system in Simplified Chinese and has not been read off a device. VoiceOver on the line has not been tried.

# Speech results that are not final carry no word times

Measured on macOS 27.2 with `SpeechTranscriber` and the `timeIndexedProgressiveTranscription` preset, 2026-11-12:

- A final result carried an audio time range for each character of Japanese text.
- A result that was not final carried a single time range covering its whole text.

So audio times cannot be used to tell which part of a guess in progress corresponds to text seen in an earlier guess. That has to be worked out from the text itself.

Not measured: a physical iPhone or iPad, English, other presets.

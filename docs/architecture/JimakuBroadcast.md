# JimakuBroadcast

The ReplayKit broadcast upload extension. The system starts it when the user confirms a screen broadcast, and hands it the audio that other apps play.

- Depends on: JimakuCore, ReplayKit, AVFoundation.
- Does one thing: converts incoming app audio to 16 kHz mono and writes it into the shared `AudioRing`. It runs no recognition, no translation, and draws nothing.
- Why so little: the system gives a broadcast upload extension a small memory budget and ends it when it goes over. Everything heavier runs in JimakuApp.
- Talks to JimakuApp only through the `AudioRing` file in the shared App Group container: samples, the broadcasting flag, and a heartbeat go to the app; the app's capture-wanted flag tells the extension whether to keep going.

# JimakuCore

A Swift package holding the app's logic that does not need a device: session state, how recognized speech is cut into caption lines, when a line is sent for translation, how captions are laid out as text. It also holds what the app and the broadcast extension must agree on: the shared audio ring and where it lives.

- Depends on: the Swift standard library and Foundation only.
- Must not import UIKit, SwiftUI, AVFoundation, ReplayKit, Speech, or Translation. Anything that touches those lives in an app or extension target and talks to JimakuCore through plain values and protocols.
- Why: this package is tested with `swift test` on a Mac, without a simulator or a device, so tests stay fast and can be written before the code.

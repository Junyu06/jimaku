# JimakuApp

The iOS and iPadOS app target: the screens the user sees and the glue between JimakuCore and the system frameworks.

- Depends on: JimakuCore, SwiftUI, and the system frameworks it needs for a given feature.
- Holds no logic that could live in JimakuCore. A view reads state from a JimakuCore type and forwards user actions to it.

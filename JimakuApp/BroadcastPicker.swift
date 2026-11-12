import ReplayKit
import SwiftUI

/// The system control that starts a screen broadcast to the Jimaku extension.
///
/// Only the system may start a broadcast, and only from this control: tapping it
/// shows the system sheet where the user confirms.
struct BroadcastPicker: UIViewRepresentable {
    /// Bundle identifier of the broadcast extension, derived from the app's own.
    static var extensionBundleIdentifier: String? {
        Bundle.main.bundleIdentifier.map { "\($0).broadcast" }
    }

    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        picker.preferredExtension = Self.extensionBundleIdentifier
        picker.showsMicrophoneButton = false
        return picker
    }

    func updateUIView(_ picker: RPSystemBroadcastPickerView, context: Context) {}
}

import ReplayKit
import SwiftUI

/// The system control that starts a screen broadcast to the Jimaku extension.
///
/// Only the system may start a broadcast, and only from this control: pressing it
/// shows the system sheet where the user confirms. The control draws a small
/// round glyph of its own, which is easy to miss, so here it is stretched over
/// the button the page draws beneath it and left all but invisible: a tap
/// anywhere on that button is a tap on the system's control.
struct BroadcastPicker: UIViewRepresentable {
    /// Whether the app owes the user the sheet without a tap. Read here so
    /// that the view is brought up to date when it changes.
    let sheetIsOwed: Bool
    /// Uses up what is owed. Returns whether to press the control now.
    let takeSheetRequest: @MainActor () -> Bool
    /// The control was pressed, by the user or by the app.
    let pressed: @MainActor () -> Void

    /// Bundle identifier of the broadcast extension, derived from the app's own.
    static var extensionBundleIdentifier: String? {
        Bundle.main.bundleIdentifier.map { "\($0).broadcast" }
    }

    func makeUIView(context: Context) -> Host {
        let host = Host()
        host.takeSheetRequest = takeSheetRequest
        host.pressed = pressed
        return host
    }

    func updateUIView(_ host: Host, context: Context) {
        host.takeSheetRequest = takeSheetRequest
        host.pressed = pressed
        if sheetIsOwed { host.pressIfOwedSoon() }
    }

    final class Host: UIView {
        /// Made at the size of its glyph, not at no size: its button follows
        /// its size, and from no size ends up with no size for good.
        private let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        var takeSheetRequest: (@MainActor () -> Bool)?
        var pressed: (@MainActor () -> Void)?
        /// The control's button, once it has been found and set up.
        private weak var button: UIButton?

        override init(frame: CGRect) {
            super.init(frame: frame)
            picker.preferredExtension = BroadcastPicker.extensionBundleIdentifier
            picker.showsMicrophoneButton = false
            // Low enough that its glyph does not show over the page's button,
            // high enough that the system still delivers touches to it.
            picker.alpha = 0.02
            addSubview(picker)
            findButton()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not used")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            // Every point of the page's button has to reach the control's
            // button, so both are given the whole of it.
            picker.frame = bounds
            // If the control made its button late, this is where it is found.
            let foundLate = button == nil && findButton()
            button?.frame = picker.bounds
            if foundLate { pressIfOwedSoon() }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            pressIfOwedSoon()
        }

        /// Presses the control once the page has finished what it is doing, if
        /// the app owes the user the sheet. Not during the update of the page
        /// itself: taking the request changes what the page reads.
        func pressIfOwedSoon() {
            DispatchQueue.main.async { [weak self] in
                self?.pressIfOwed()
            }
        }

        /// Presses the system's control as a tap would. It offers no call that
        /// shows its sheet, so this sends its button the tap. If a later system
        /// builds the control without a button to find, nothing is pressed.
        private func pressIfOwed() {
            guard window != nil, let button, takeSheetRequest?() == true else { return }
            button.sendActions(for: .touchUpInside)
        }

        /// Looks for the control's button and sets it up once. Returns whether
        /// one was found.
        @discardableResult
        private func findButton() -> Bool {
            guard let found = picker.subviews.lazy.compactMap({ $0 as? UIButton }).first else { return false }
            // The page's own button is hidden from assistive technology; the
            // one that acts carries its name.
            found.accessibilityLabel = "打开录屏"
            // A press by the user settles what the app owed as well.
            found.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
            button = found
            return true
        }

        @objc private func buttonPressed() {
            pressed?()
        }
    }
}

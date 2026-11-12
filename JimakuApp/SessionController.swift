import JimakuCore
import Observation

/// Connects the session state in JimakuCore to the floating caption window.
///
/// Captions are scripted demo text for now; audio capture, recognition, and
/// translation are not connected yet.
@MainActor
@Observable
final class SessionController {
    private(set) var session = CaptionSession()

    /// A message for the user when the session cannot run. Nil when all is well.
    private(set) var notice: String?

    let window = CaptionWindow()

    private var demoTask: Task<Void, Never>?

    func prepare() {
        window.onClosed = { [weak self] in self?.windowDidClose() }
        window.prepare()
        window.show(DemoCaptions.lines(at: 0))
    }

    func performPrimaryAction() {
        switch session.primaryAction {
        case .start: start()
        case .stop: stop()
        }
    }

    private func start() {
        guard window.isSupported else {
            notice = "这台设备不支持画中画，悬浮窗开不了。"
            return
        }
        notice = nil
        session.start()
        window.float()
        startDemoCaptions()
    }

    private func stop() {
        session.stop()
        stopDemoCaptions()
        window.close()
    }

    private func windowDidClose() {
        guard session.state == .running else { return }
        session.stop()
        stopDemoCaptions()
    }

    private func startDemoCaptions() {
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            var tick = 0
            while !Task.isCancelled {
                self?.window.show(DemoCaptions.lines(at: tick))
                tick += 1
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private func stopDemoCaptions() {
        demoTask?.cancel()
        demoTask = nil
    }
}

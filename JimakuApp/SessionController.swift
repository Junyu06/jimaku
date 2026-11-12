import JimakuCore
import Observation

/// Connects the session state in JimakuCore to the floating caption window and to
/// the audio arriving from the broadcast extension.
///
/// Captions are scripted demo text for now; recognition and translation are not
/// connected yet. The audio is only shown as a level meter.
@MainActor
@Observable
final class SessionController {
    private(set) var session = CaptionSession()

    /// A message for the user when the session cannot run. Nil when all is well.
    private(set) var notice: String?

    /// What is known about the incoming audio while a session runs.
    private(set) var audioStatus: AudioMonitor.Status = .notBroadcasting

    let window = CaptionWindow()

    private let audio = AudioMonitor()
    private var demoTask: Task<Void, Never>?
    private var audioTask: Task<Void, Never>?

    func prepare() {
        window.onClosed = { [weak self] in self?.windowDidClose() }
        window.prepare()
        window.show(DemoCaptions.lines(at: 0))
        audioStatus = audio.status
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
        startAudio()
    }

    private func stop() {
        session.stop()
        stopTasks()
        audio.requestBroadcastStop()
        window.close()
    }

    private func windowDidClose() {
        guard session.state == .running else { return }
        session.stop()
        stopTasks()
        audio.requestBroadcastStop()
    }

    private func stopTasks() {
        demoTask?.cancel()
        demoTask = nil
        audioTask?.cancel()
        audioTask = nil
        window.show(audioLevel: nil)
        #if targetEnvironment(simulator)
            audio.endSimulatedBroadcast()
        #endif
        audioStatus = audio.status
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

    /// Reads the shared ring ten times a second and shows the level in the window.
    private func startAudio() {
        audioTask?.cancel()
        audio.skipToNow()
        audioTask = Task { [weak self] in
            let interval = 0.1
            var elapsed = 0.0
            while !Task.isCancelled {
                guard let self else { return }
                #if targetEnvironment(simulator)
                    self.audio.writeSimulatedAudio(elapsed: elapsed, duration: interval)
                #endif
                let samples = self.audio.readNewSamples()
                let status = self.audio.status
                self.audioStatus = status
                self.window.show(audioLevel: status == .notBroadcasting || status == .unavailable
                    ? nil
                    : AudioLevel.meter(for: samples))
                elapsed += interval
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
}

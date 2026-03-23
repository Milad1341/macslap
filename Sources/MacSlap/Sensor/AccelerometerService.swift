import Foundation
import Combine

final class AccelerometerService: ObservableObject {
    enum Status: Equatable {
        case idle
        case running
        case error(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var latestSample: AccelerometerSample?

    let samplePublisher = PassthroughSubject<AccelerometerSample, Never>()

    private let bridge = IOKitHIDBridge()
    private let queue = DispatchQueue(label: "com.macslap.accelerometer", qos: .userInteractive)

    var isAvailable: Bool {
        IOKitHIDBridge.isAvailable()
    }

    var needsPrivileges: Bool {
        if case .error(let msg) = status, msg.contains("sudo") {
            return true
        }
        return false
    }

    func start() {
        guard status != .running else { return }
        DispatchQueue.main.async { self.status = .idle }

        queue.async { [weak self] in
            guard let self else { return }
            do {
                DispatchQueue.main.async { self.status = .running }
                try self.bridge.start { [weak self] sample in
                    guard let self else { return }
                    self.samplePublisher.send(sample)
                }
            } catch {
                print("[MacSlap] Sensor error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.status = .error(error.localizedDescription)
                }
            }
        }
    }

    func stop() {
        bridge.stop()
        DispatchQueue.main.async {
            self.status = .idle
        }
    }

    /// Relaunch the whole app with root privileges via AppleScript
    func relaunchWithPrivileges() {
        guard let execURL = Bundle.main.executableURL else { return }
        let script = "do shell script \"\\\"\(execURL.path)\\\"\" with administrator privileges"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}

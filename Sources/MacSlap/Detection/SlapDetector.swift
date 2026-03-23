import Foundation
import Combine

final class SlapDetector: ObservableObject {
    let slapPublisher = PassthroughSubject<SlapEvent, Never>()

    @Published var sensitivity: Double = 0.05
    @Published var cooldownMs: Int = 750

    // High-pass filter state (removes gravity)
    private var prevInput = (x: 0.0, y: 0.0, z: 0.0)
    private var filtered = (x: 0.0, y: 0.0, z: 0.0)
    private let alpha = 0.95

    // STA/LTA state
    private var sta: Double = 0
    private var lta: Double = 0.001
    private let staWindow: Double = 5    // ~50ms at 100Hz
    private let ltaWindow: Double = 100  // ~1s at 100Hz
    private let staLtaThreshold: Double = 3.0

    // Cooldown
    private var lastSlapTime: Date = .distantPast

    private var cancellable: AnyCancellable?
    private var sampleCount = 0

    func attach(to service: AccelerometerService) {
        cancellable = service.samplePublisher
            .receive(on: DispatchQueue(label: "com.macslap.detection", qos: .userInteractive))
            .sink { [weak self] sample in
                self?.processSample(sample)
            }
    }

    func detach() {
        cancellable?.cancel()
        cancellable = nil
        reset()
    }

    func reset() {
        prevInput = (0, 0, 0)
        filtered = (0, 0, 0)
        sta = 0
        lta = 0.001
        sampleCount = 0
    }

    private func processSample(_ sample: AccelerometerSample) {
        // High-pass filter to remove gravity
        let hx = alpha * (filtered.x + sample.x - prevInput.x)
        let hy = alpha * (filtered.y + sample.y - prevInput.y)
        let hz = alpha * (filtered.z + sample.z - prevInput.z)

        prevInput = (sample.x, sample.y, sample.z)
        filtered = (hx, hy, hz)

        sampleCount += 1
        // Let the filter settle for 50 samples before detecting
        guard sampleCount > 50 else { return }

        let magnitude = (hx * hx + hy * hy + hz * hz).squareRoot()

        // Update STA/LTA
        let energy = magnitude * magnitude
        sta += (energy - sta) / staWindow
        lta += (energy - lta) / ltaWindow
        let ratio = sta / max(lta, 1e-10)

        // Check detection conditions
        let amplitudeTriggered = magnitude > sensitivity
        let ratioTriggered = ratio > staLtaThreshold

        guard amplitudeTriggered || ratioTriggered else { return }
        // Also require minimum amplitude to avoid phantom triggers
        guard magnitude > 0.02 else { return }

        // Cooldown check
        let now = Date()
        let elapsed = now.timeIntervalSince(lastSlapTime) * 1000
        guard elapsed > Double(cooldownMs) else { return }
        lastSlapTime = now

        // Reset STA after detection so aftershock doesn't retrigger
        sta = 0

        let event = SlapEvent(amplitude: magnitude)
        slapPublisher.send(event)
    }
}

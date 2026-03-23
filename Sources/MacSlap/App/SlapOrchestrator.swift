import Foundation
import Combine
import SwiftUI

@MainActor
final class SlapOrchestrator: ObservableObject {
    var settings = AppSettings()
    let accelerometer = AccelerometerService()
    let detector = SlapDetector()
    let audioPlayer = AudioPlayer()
    let soundPackManager = SoundPackManager()

    @Published var lastSlap: SlapEvent?
    @Published var slapCount: Int = 0
    @Published var showSlapFlash: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        syncSettings()
        bindDetection()

        // Forward nested ObservableObject changes so SwiftUI views update
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.syncSettings()
            }
            .store(in: &cancellables)

        accelerometer.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Auto-start
        if settings.isEnabled {
            start()
        }
    }

    func start() {
        accelerometer.start()
        detector.attach(to: accelerometer)
    }

    func stop() {
        detector.detach()
        accelerometer.stop()
    }

    func toggle() {
        settings.isEnabled.toggle()
        if settings.isEnabled {
            start()
        } else {
            stop()
        }
    }

    func testSlap() {
        let event = SlapEvent(amplitude: 0.25)
        handleSlap(event)
    }

    // MARK: - Private

    private func syncSettings() {
        detector.sensitivity = settings.sensitivity
        detector.cooldownMs = settings.cooldownMs
        audioPlayer.volume = Float(settings.volume)
        audioPlayer.scaleVolumeByForce = settings.scaleVolumeByForce
        soundPackManager.selectedPackName = settings.selectedSoundPack
    }

    private func bindDetection() {
        detector.slapPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleSlap(event)
            }
            .store(in: &cancellables)
    }

    private func handleSlap(_ event: SlapEvent) {
        lastSlap = event
        slapCount += 1

        // Flash the menu bar icon
        showSlapFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showSlapFlash = false
        }

        // Play sound
        if let url = soundPackManager.pickSound(for: event) {
            audioPlayer.play(url: url, amplitude: event.amplitude)
        }
    }
}

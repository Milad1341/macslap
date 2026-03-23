import Foundation
import AVFoundation

final class AudioPlayer: ObservableObject {
    @Published var volume: Float = 0.8
    @Published var scaleVolumeByForce: Bool = true

    private var players: [AVAudioPlayer] = []

    func play(url: URL, amplitude: Double = 1.0) {
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            print("[MacSlap] Failed to load audio: \(url.lastPathComponent)")
            return
        }

        // Scale volume by slap force if enabled
        let forceMultiplier: Float = scaleVolumeByForce
            ? Float(min(amplitude * 3.0, 1.5))
            : 1.0
        player.volume = min(volume * forceMultiplier, 1.0)

        // Stop any currently playing sound so they don't overlap
        stopAll()

        player.prepareToPlay()
        player.play()

        players.append(player)
    }

    func playTest(url: URL) {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = volume
        player.prepareToPlay()
        player.play()
        players.append(player)
        players.removeAll { !$0.isPlaying }
    }

    func stopAll() {
        players.forEach { $0.stop() }
        players.removeAll()
    }
}

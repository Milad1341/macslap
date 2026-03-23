import SwiftUI

final class AppSettings: ObservableObject {
    @AppStorage("isEnabled") var isEnabled: Bool = true
    @AppStorage("sensitivity") var sensitivity: Double = 0.05
    @AppStorage("volume") var volume: Double = 0.8
    @AppStorage("cooldownMs") var cooldownMs: Int = 750
    @AppStorage("selectedSoundPack") var selectedSoundPack: String = "Default"
    @AppStorage("scaleVolumeByForce") var scaleVolumeByForce: Bool = true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
}

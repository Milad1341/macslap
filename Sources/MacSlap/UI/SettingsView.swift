import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var orchestrator: SlapOrchestrator

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            audioTab
                .tabItem {
                    Label("Audio", systemImage: "speaker.wave.2")
                }
        }
        .frame(width: 420, height: 320)
    }

    private var generalTab: some View {
        Form {
            Section("Detection") {
                Toggle("Enable slap detection", isOn: Binding(
                    get: { orchestrator.settings.isEnabled },
                    set: { _ in orchestrator.toggle() }
                ))

                VStack(alignment: .leading) {
                    HStack {
                        Text("Sensitivity")
                        Spacer()
                        Text(String(format: "%.3fg", orchestrator.settings.sensitivity))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $orchestrator.settings.sensitivity, in: 0.01...0.3) {
                        Text("Sensitivity")
                    } minimumValueLabel: {
                        Text("Less")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Text("More")
                            .font(.caption2)
                    }
                }

                HStack {
                    Text("Cooldown")
                    Spacer()
                    TextField("", value: $orchestrator.settings.cooldownMs, format: .number)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                    Text("ms")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Sensor") {
                HStack {
                    Text("Accelerometer")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(orchestrator.accelerometer.status == .running ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(orchestrator.accelerometer.status == .running ? "Connected" : "Disconnected")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var audioTab: some View {
        Form {
            Section("Playback") {
                if !orchestrator.soundPackManager.packs.isEmpty {
                    Picker("Sound Pack", selection: $orchestrator.settings.selectedSoundPack) {
                        ForEach(orchestrator.soundPackManager.packs) { pack in
                            Text(pack.name).tag(pack.name)
                        }
                    }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Volume")
                        Spacer()
                        Text("\(Int(orchestrator.settings.volume * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $orchestrator.settings.volume, in: 0...1) {
                        Text("Volume")
                    } minimumValueLabel: {
                        Image(systemName: "speaker")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Image(systemName: "speaker.wave.3")
                            .font(.caption2)
                    }
                }

                Toggle("Scale volume by slap force", isOn: $orchestrator.settings.scaleVolumeByForce)
            }

            Section {
                HStack {
                    Button("Test Sound") {
                        orchestrator.testSlap()
                    }

                    Spacer()

                    Button("Open Sound Packs Folder") {
                        orchestrator.soundPackManager.openUserSoundPacksFolder()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

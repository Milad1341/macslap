import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var orchestrator: SlapOrchestrator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("MacSlap")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { orchestrator.settings.isEnabled },
                    set: { _ in orchestrator.toggle() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            Divider()

            // Status
            statusSection

            Divider()

            // Quick controls
            controlsSection

            Divider()

            // Actions
            Button("Test Slap") {
                orchestrator.testSlap()
            }

            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Divider()

            Button("Quit MacSlap") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 260)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if orchestrator.accelerometer.needsPrivileges {
                Button("Grant Sensor Access...") {
                    orchestrator.accelerometer.relaunchWithPrivileges()
                }
                .font(.caption)
            }

            if let lastSlap = orchestrator.lastSlap {
                Text("Last: \(lastSlap.severity.rawValue) (\(String(format: "%.2fg", lastSlap.amplitude)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Slaps detected: \(orchestrator.slapCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sensitivity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(
                    value: $orchestrator.settings.sensitivity,
                    in: 0.01...0.3
                )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Volume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(
                    value: $orchestrator.settings.volume,
                    in: 0...1
                )
            }

            if !orchestrator.soundPackManager.packs.isEmpty {
                Picker("Sound Pack", selection: $orchestrator.settings.selectedSoundPack) {
                    ForEach(orchestrator.soundPackManager.packs) { pack in
                        Text(pack.name).tag(pack.name)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var statusColor: Color {
        switch orchestrator.accelerometer.status {
        case .running:
            return orchestrator.settings.isEnabled ? .green : .yellow
        case .error:
            return .red
        case .idle:
            return .gray
        }
    }

    private var statusText: String {
        switch orchestrator.accelerometer.status {
        case .running:
            return orchestrator.settings.isEnabled ? "Listening..." : "Paused"
        case .error(let msg):
            return "Error: \(msg)"
        case .idle:
            return "Idle"
        }
    }
}

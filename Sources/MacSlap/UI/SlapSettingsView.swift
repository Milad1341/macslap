import SwiftUI

struct SlapSettingsView: View {
    @EnvironmentObject var orchestrator: SlapOrchestrator
    @State private var showResetConfirm = false

    private let orange = Color(red: 0.91, green: 0.53, blue: 0.23)
    private let darkBlue = Color(red: 0.18, green: 0.30, blue: 0.44)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(darkBlue)

                    Text("Fine-tune your slap experience")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.gray)
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 24)

                // Detection section
                settingsSection(title: "Slap Detection", icon: "waveform.path.ecg") {
                    VStack(spacing: 16) {
                        // Sensitivity
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Sensitivity")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                Spacer()
                                Text(sensitivityLabel)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(orange.opacity(0.12))
                                    )
                            }

                            HStack(spacing: 8) {
                                Text("Hair Trigger")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.gray)
                                Slider(value: $orchestrator.settings.sensitivity, in: 0.01...0.3)
                                    .accentColor(orange)
                                Text("Gorilla Mode")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.gray)
                            }

                            Text("Higher sensitivity = lighter slaps detected. Current threshold: \(String(format: "%.3fg", orchestrator.settings.sensitivity))")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.gray.opacity(0.8))
                        }

                        Divider()

                        // Cooldown
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cooldown")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                Text("Minimum time between detected slaps")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.gray.opacity(0.8))
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                TextField("", value: $orchestrator.settings.cooldownMs, format: .number)
                                    .frame(width: 60)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                Text("ms")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.gray)
                            }
                        }
                    }
                }

                // Sensor section
                settingsSection(title: "Sensor Status", icon: "cpu") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Accelerometer")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text("Built-in motion sensor used for slap detection")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.gray.opacity(0.8))
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Circle()
                                .fill(sensorColor)
                                .frame(width: 8, height: 8)
                            Text(sensorStatus)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(sensorColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(sensorColor.opacity(0.1))
                        )
                    }
                }

                // Startup section
                settingsSection(title: "General", icon: "gearshape") {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Launch at Login")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                Text("Start MacSlap when you log in to your Mac")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.gray.opacity(0.8))
                            }
                            Spacer()
                            Toggle("", isOn: $orchestrator.settings.launchAtLogin)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .labelsHidden()
                        }
                    }
                }

                // Danger zone
                settingsSection(title: "Danger Zone", icon: "exclamationmark.triangle.fill", titleColor: .red) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset Slap Counter")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text("Your glorious slap count will be lost forever")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.gray.opacity(0.8))
                        }

                        Spacer()

                        Button {
                            showResetConfirm = true
                        } label: {
                            Text("Reset")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .alert("Reset slap counter?", isPresented: $showResetConfirm) {
                            Button("Reset", role: .destructive) {
                                orchestrator.slapCount = 0
                            }
                            Button("Keep My Slaps", role: .cancel) { }
                        } message: {
                            Text("You've accumulated \(orchestrator.slapCount) slaps. This cannot be undone!")
                        }
                    }
                }

                // App info
                VStack(spacing: 4) {
                    Text("MacSlap v1.0")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.gray)
                    Text("Your Mac had it coming.")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.gray.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        titleColor: Color = Color(red: 0.18, green: 0.30, blue: 0.44),
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(titleColor)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor)
            }

            content()
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                )
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 20)
    }

    private var sensitivityLabel: String {
        let s = orchestrator.settings.sensitivity
        if s < 0.05 { return "Hair Trigger" }
        if s < 0.1  { return "Sensitive" }
        if s < 0.15 { return "Normal" }
        if s < 0.2  { return "Firm" }
        return "Gorilla Mode"
    }

    private var sensorColor: Color {
        switch orchestrator.accelerometer.status {
        case .running: return .green
        case .error:   return .red
        case .idle:    return .gray
        }
    }

    private var sensorStatus: String {
        switch orchestrator.accelerometer.status {
        case .running:        return "Connected"
        case .error(let msg): return "Error: \(msg)"
        case .idle:           return "Idle"
        }
    }
}

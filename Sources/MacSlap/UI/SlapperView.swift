import SwiftUI

struct SlapperView: View {
    @EnvironmentObject var orchestrator: SlapOrchestrator

    @State private var isPulsing = false
    @State private var slapShake = false

    private let orange = Color(red: 0.91, green: 0.53, blue: 0.23)
    private let darkBlue = Color(red: 0.18, green: 0.30, blue: 0.44)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal, 32)
                .padding(.top, 24)

            Spacer()

            // Big slap button
            bigSlapButton

            Spacer()

            // Stats bar
            statsBar
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: orchestrator.slapCount) { newCount in
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                slapShake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                slapShake = false
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Slap Control Center")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(darkBlue)

                Text(orchestrator.settings.isEnabled ? "Listening for slaps..." : "Slap detection is off")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.gray)
            }

            Spacer()

            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .fill(statusColor.opacity(0.4))
                            .frame(width: 20, height: 20)
                            .scaleEffect(isPulsing && orchestrator.settings.isEnabled ? 1.5 : 1.0)
                            .opacity(isPulsing && orchestrator.settings.isEnabled ? 0 : 0.5)
                            .animation(
                                .easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                                value: isPulsing
                            )
                    )

                Text(statusText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.1))
            )
            .onAppear { isPulsing = true }
        }
    }

    private var bigSlapButton: some View {
        VStack(spacing: 20) {
            Button {
                orchestrator.toggle()
            } label: {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            orchestrator.settings.isEnabled
                                ? orange.opacity(0.2)
                                : Color.gray.opacity(0.15),
                            lineWidth: 4
                        )
                        .frame(width: 200, height: 200)

                    // Inner circle
                    Circle()
                        .fill(
                            orchestrator.settings.isEnabled
                                ? LinearGradient(
                                    colors: [orange, Color(red: 0.85, green: 0.40, blue: 0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 170, height: 170)
                        .shadow(
                            color: orchestrator.settings.isEnabled ? orange.opacity(0.4) : .clear,
                            radius: 20,
                            y: 8
                        )

                    // Icon & text
                    VStack(spacing: 8) {
                        Image(systemName: orchestrator.settings.isEnabled ? "hand.raised.fill" : "hand.raised.slash.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)

                        Text(orchestrator.settings.isEnabled ? "LISTENING" : "START")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .tracking(2)
                    }
                }
                .offset(x: slapShake ? -6 : 0)
                .animation(.default, value: slapShake)
            }
            .buttonStyle(.plain)

            Text(orchestrator.settings.isEnabled ? "Tap to stop" : "Tap to start listening")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.gray)

            // Test slap button
            Button {
                orchestrator.testSlap()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 12))
                    Text("Test Slap")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .stroke(orange, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var statsBar: some View {
        HStack(spacing: 16) {
            statCard(
                icon: "number",
                title: "Slap Count",
                value: "\(orchestrator.slapCount)",
                color: darkBlue
            )

            if let lastSlap = orchestrator.lastSlap {
                statCard(
                    icon: "bolt.fill",
                    title: "Last Force",
                    value: String(format: "%.2fg", lastSlap.amplitude),
                    color: orange
                )

                statCard(
                    icon: "gauge.medium",
                    title: "Severity",
                    value: lastSlap.severity.rawValue.capitalized,
                    color: severityColor(lastSlap.severity)
                )
            } else {
                statCard(
                    icon: "bolt.fill",
                    title: "Last Force",
                    value: "---",
                    color: .gray
                )

                statCard(
                    icon: "gauge.medium",
                    title: "Severity",
                    value: "---",
                    color: .gray
                )
            }

            statCard(
                icon: "speaker.wave.2.fill",
                title: "Volume",
                value: "\(Int(orchestrator.settings.volume * 100))%",
                color: .green
            )
        }
    }

    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(darkBlue)
                .monospacedDigit()

            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
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
            return orchestrator.settings.isEnabled ? "Active" : "Paused"
        case .error:
            return "Error"
        case .idle:
            return "Idle"
        }
    }

    private func severityColor(_ severity: SlapSeverity) -> Color {
        switch severity {
        case .light:  return .green
        case .medium: return .yellow
        case .hard:   return .red
        }
    }
}

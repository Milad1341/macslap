import SwiftUI

enum SlapTab: String, CaseIterable {
    case welcome = "Welcome"
    case slapper = "Slapper"
    case sounds  = "Sounds"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .welcome:  return "hand.wave.fill"
        case .slapper:  return "hand.raised.fill"
        case .sounds:   return "speaker.wave.3.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var funLabel: String {
        switch self {
        case .welcome:  return "Howdy!"
        case .slapper:  return "Slap It!"
        case .sounds:   return "Sounds"
        case .settings: return "Tweaks"
        }
    }
}

struct MainWindowView: View {
    @EnvironmentObject var orchestrator: SlapOrchestrator
    @State private var selectedTab: SlapTab = .welcome
    @State private var hoveredTab: SlapTab?

    private let sidebarGradient = LinearGradient(
        colors: [Color(red: 0.18, green: 0.30, blue: 0.44), Color(red: 0.12, green: 0.22, blue: 0.35)],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        HStack(spacing: 0) {
            // Custom sidebar
            sidebar

            // Main content
            ZStack {
                Color(red: 0.94, green: 0.93, blue: 0.90)

                Group {
                    switch selectedTab {
                    case .welcome:
                        WelcomeView(onGetStarted: { withAnimation(.spring(response: 0.4)) { selectedTab = .slapper } })
                    case .slapper:
                        SlapperView()
                    case .sounds:
                        SoundPickerView()
                    case .settings:
                        SlapSettingsView()
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .frame(minWidth: 700, minHeight: 480)
        .environmentObject(orchestrator)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Logo area
            VStack(spacing: 6) {
                if let logoImage = loadLogo() {
                    Image(nsImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                }

                Text("MacSlap")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("v1.0")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Tab buttons
            VStack(spacing: 4) {
                ForEach(SlapTab.allCases, id: \.self) { tab in
                    sidebarButton(tab)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Slap counter badge
            VStack(spacing: 4) {
                Text("\(orchestrator.slapCount)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.91, green: 0.53, blue: 0.23))

                Text("Total Slaps")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.bottom, 12)

            // Credit
            Text("Developed by Milad")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.91, green: 0.53, blue: 0.23))
                .padding(.bottom, 16)
        }
        .frame(width: 140)
        .background(sidebarGradient)
    }

    private func sidebarButton(_ tab: SlapTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 20)

                Text(tab.funLabel)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTab == tab
                        ? Color.white.opacity(0.15)
                        : hoveredTab == tab
                            ? Color.white.opacity(0.08)
                            : Color.clear)
            )
            .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.65))
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            hoveredTab = isHovered ? tab : nil
        }
    }

    private func loadLogo() -> NSImage? {
        guard let url = Bundle.module.url(forResource: "MacSlap", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }
}

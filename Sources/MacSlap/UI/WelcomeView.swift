import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoRotation: Double = -10
    @State private var showTagline = false
    @State private var showFeatures = false
    @State private var showButton = false
    @State private var handWiggle = false

    private let orange = Color(red: 0.91, green: 0.53, blue: 0.23)
    private let darkBlue = Color(red: 0.18, green: 0.30, blue: 0.44)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo with bounce-in
            VStack(spacing: 16) {
                if let logoImage = loadLogo() {
                    Image(nsImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .scaleEffect(logoScale)
                        .rotationEffect(.degrees(logoRotation))
                        .shadow(color: orange.opacity(0.4), radius: 20, y: 8)
                }

                if showTagline {
                    VStack(spacing: 8) {
                        Text("Your Mac asked for it.")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(darkBlue)

                        Text("Slap your MacBook. It slaps back with sound.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.gray)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            if showFeatures {
                // Feature cards
                HStack(spacing: 16) {
                    featureCard(
                        icon: "waveform.path",
                        title: "Detects Slaps",
                        description: "Uses your Mac's accelerometer to feel the impact",
                        color: .blue
                    )
                    featureCard(
                        icon: "speaker.wave.3.fill",
                        title: "Plays Sounds",
                        description: "Choose from sound packs or add your own audio files",
                        color: orange
                    )
                    featureCard(
                        icon: "slider.horizontal.3",
                        title: "Tunable",
                        description: "Adjust sensitivity, volume, and cooldown to your liking",
                        color: .green
                    )
                }
                .padding(.horizontal, 40)
                .padding(.top, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()

            if showButton {
                Button(action: onGetStarted) {
                    HStack(spacing: 8) {
                        Text("Let's Slap")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 16, weight: .bold))
                            .rotationEffect(.degrees(handWiggle ? 15 : -15))
                            .animation(
                                .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                                value: handWiggle
                            )
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [orange, Color(red: 0.85, green: 0.40, blue: 0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: orange.opacity(0.4), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear { handWiggle = true }
            }

            // Credit shown in sidebar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { animateEntrance() }
    }

    private func featureCard(icon: String, title: String, description: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.12))
                )

            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.18, green: 0.30, blue: 0.44))

            Text(description)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            logoScale = 1.0
            logoRotation = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showTagline = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            showFeatures = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
            showButton = true
        }
    }

    private func loadLogo() -> NSImage? {
        guard let url = Bundle.module.url(forResource: "MacSlap", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }
}

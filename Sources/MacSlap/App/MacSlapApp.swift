import SwiftUI
import Security

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Show as a regular app with dock icon
        NSApp.setActivationPolicy(.regular)

        // Set the app icon to our MacSlap logo
        if let logoURL = Bundle.appResources.url(forResource: "MacSlap", withExtension: "png"),
           let logoImage = NSImage(contentsOf: logoURL) {
            NSApp.applicationIconImage = logoImage
        }
    }
}

@main
struct MacSlapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var orchestrator = SlapOrchestrator()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(orchestrator)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 700, height: 480)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(orchestrator)
        } label: {
            Image(systemName: orchestrator.showSlapFlash ? "hand.raised.fill" : "hand.raised")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(orchestrator)
        }
    }
}

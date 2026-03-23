import Foundation

// Override SPM's auto-generated Bundle.module to also search Contents/Resources/
// inside a .app bundle. The generated accessor only checks Bundle.main.bundleURL
// (the .app root), but codesign requires resources in Contents/Resources/.
extension Foundation.Bundle {
    static let appResources: Bundle = {
        let bundleName = "MacSlap_MacSlap"

        // Standard .app bundle location: Contents/Resources/
        if let resourceURL = Bundle.main.resourceURL {
            let bundlePath = resourceURL.appendingPathComponent(bundleName + ".bundle")
            if let bundle = Bundle(path: bundlePath.path) {
                return bundle
            }
        }

        // Fallback: .app root (SPM default)
        let mainPath = Bundle.main.bundleURL.appendingPathComponent(bundleName + ".bundle")
        if let bundle = Bundle(path: mainPath.path) {
            return bundle
        }

        // Fallback: next to the binary (debug/development)
        let executableURL = Bundle.main.executableURL?.deletingLastPathComponent()
        if let execDir = executableURL {
            let bundlePath = execDir.appendingPathComponent(bundleName + ".bundle")
            if let bundle = Bundle(path: bundlePath.path) {
                return bundle
            }
        }

        fatalError("Could not find resource bundle \(bundleName)")
    }()
}

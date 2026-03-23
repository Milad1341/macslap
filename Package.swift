// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacSlap",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacSlap",
            resources: [
                .copy("Resources/SoundPacks"),
                .copy("Resources/MacSlap.png")
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
            ]
        )
    ]
)

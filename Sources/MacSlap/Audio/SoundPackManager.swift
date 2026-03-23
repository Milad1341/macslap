import Foundation
import AppKit
import AVFoundation

struct SoundPack: Identifiable, Codable {
    let name: String
    let description: String
    let mode: PlayMode
    let files: [String]

    var id: String { name }

    enum PlayMode: String, Codable {
        case random
        case escalation
    }
}

final class SoundPackManager: ObservableObject {
    @Published private(set) var packs: [SoundPack] = []
    @Published var selectedPackName: String = "Default"

    private var packDirectories: [String: URL] = [:]

    var selectedPack: SoundPack? {
        packs.first { $0.name == selectedPackName }
    }

    init() {
        loadPacks()
    }

    func loadPacks() {
        var discovered: [SoundPack] = []

        // Load from app bundle
        if let bundledURL = Bundle.module.url(forResource: "SoundPacks", withExtension: nil) {
            discovered += discoverPacks(in: bundledURL)
        }

        // Load from Application Support (user-added packs)
        if let supportURL = userSoundPacksURL() {
            discovered += discoverPacks(in: supportURL)
        }

        packs = discovered
    }

    func audioURL(for filename: String, in pack: SoundPack) -> URL? {
        guard let dir = packDirectories[pack.name] else { return nil }
        let url = dir.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func pickSound(for event: SlapEvent) -> URL? {
        guard let pack = selectedPack, !pack.files.isEmpty else { return nil }

        let filename: String
        switch pack.mode {
        case .random:
            filename = pack.files.randomElement()!
        case .escalation:
            let index: Int
            switch event.severity {
            case .light:
                index = 0
            case .medium:
                index = pack.files.count / 2
            case .hard:
                index = pack.files.count - 1
            }
            filename = pack.files[min(index, pack.files.count - 1)]
        }

        return audioURL(for: filename, in: pack)
    }

    func openUserSoundPacksFolder() {
        guard let url = userSoundPacksURL(create: true) else { return }
        NSWorkspace.shared.open(url)
    }

    /// Validate that an audio file is MP3 and between 3-5 seconds long
    func validateAudioFile(at url: URL) -> AudioValidationResult {
        // Check extension
        guard url.pathExtension.lowercased() == "mp3" else {
            return .invalid("Not an MP3 file")
        }

        // Check duration using AVAudioFile (synchronous)
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            return .invalid("Could not read audio file")
        }
        let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate

        if duration > 10.0 {
            return .invalid("Too long (\(String(format: "%.1f", duration))s) — maximum is 10 seconds")
        }

        return .valid(duration: duration)
    }

    enum AudioValidationResult {
        case valid(duration: Double)
        case invalid(String)

        var isValid: Bool {
            if case .valid = self { return true }
            return false
        }

        var errorMessage: String? {
            if case .invalid(let msg) = self { return msg }
            return nil
        }
    }

    /// Create a new sound pack from user-selected MP3 files
    func createPack(name: String, description: String, mode: SoundPack.PlayMode, sourceFiles: [URL]) throws {
        guard let baseURL = userSoundPacksURL(create: true) else {
            throw PackError.noSupportDirectory
        }

        // Create pack folder
        let packDir = baseURL.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)

        // Copy audio files
        var fileNames: [String] = []
        for sourceURL in sourceFiles {
            let fileName = sourceURL.lastPathComponent
            let destURL = packDir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            fileNames.append(fileName)
        }

        // Create pack.json
        let pack = SoundPack(name: name, description: description, mode: mode, files: fileNames)
        let data = try JSONEncoder().encode(pack)
        let jsonURL = packDir.appendingPathComponent("pack.json")
        try data.write(to: jsonURL)

        // Reload
        loadPacks()
    }

    /// Delete a user-created sound pack
    func deletePack(named name: String) {
        guard let baseURL = userSoundPacksURL() else { return }
        let packDir = baseURL.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: packDir)
        loadPacks()
    }

    /// Check if a pack is user-created (not bundled)
    func isUserPack(_ pack: SoundPack) -> Bool {
        guard let baseURL = userSoundPacksURL(),
              let packDir = packDirectories[pack.name] else { return false }
        return packDir.path.hasPrefix(baseURL.path)
    }

    enum PackError: LocalizedError {
        case noSupportDirectory

        var errorDescription: String? {
            switch self {
            case .noSupportDirectory: return "Could not access Application Support directory"
            }
        }
    }

    // MARK: - Private

    private func discoverPacks(in directory: URL) -> [SoundPack] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return [] }

        return contents.compactMap { dir in
            let manifestURL = dir.appendingPathComponent("pack.json")
            guard let data = try? Data(contentsOf: manifestURL),
                  let pack = try? JSONDecoder().decode(SoundPack.self, from: data) else {
                return nil
            }
            packDirectories[pack.name] = dir
            return pack
        }
    }

    private func userSoundPacksURL(create: Bool = false) -> URL? {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = support.appendingPathComponent("MacSlap/SoundPacks")
        if create {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}

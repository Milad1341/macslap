import SwiftUI

struct SoundPickerView: View {
    @EnvironmentObject var orchestrator: SlapOrchestrator
    @State private var hoveredPack: String?

    // Upload flow
    @State private var showUploadFlow = false
    @State private var selectedFiles: [URL] = []
    @State private var validationErrors: [String] = []
    @State private var packName = ""
    @State private var uploadStep: UploadStep = .pickFiles
    @State private var isCreating = false
    @State private var createError: String?
    @State private var showDeleteConfirm: String? = nil

    enum UploadStep {
        case pickFiles
        case namePack
        case done
    }

    private let orange = Color(red: 0.91, green: 0.53, blue: 0.23)
    private let darkBlue = Color(red: 0.18, green: 0.30, blue: 0.44)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Sound Packs")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(darkBlue)

                Text("Pick what your Mac screams when you slap it")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.gray)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Volume control
            volumeControl
                .padding(.horizontal, 32)
                .padding(.bottom, 20)

            // Upload your own section (always visible above scroll)
            uploadSection
                .padding(.horizontal, 32)
                .padding(.bottom, 20)

            // Sound packs
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !orchestrator.soundPackManager.packs.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(orchestrator.soundPackManager.packs) { pack in
                                soundPackCard(pack)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }

            // empty spacer to keep layout
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showUploadFlow) {
            uploadSheet
        }
    }

    // MARK: - Upload Section

    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(orange)
                Text("Create Your Own Sound Pack")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(darkBlue)
            }

            // Requirements
            VStack(alignment: .leading, spacing: 8) {
                requirementRow(icon: "doc.fill", text: "Files must be MP3 format")
                requirementRow(icon: "timer", text: "Each sound must be 10 seconds or less")
                requirementRow(icon: "number", text: "Choose between 5 and 10 sounds per pack")
            }

            Button {
                resetUploadFlow()
                showUploadFlow = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 14))
                    Text("Upload Sounds")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(orange)
                )
                .shadow(color: orange.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    private func requirementRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(orange)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.gray)
        }
    }

    // MARK: - Upload Sheet

    private var uploadSheet: some View {
        VStack(spacing: 0) {
            // Sheet header
            HStack {
                Text(uploadStep == .namePack ? "Name Your Sound Pack" : uploadStep == .done ? "All Done!" : "Select Your Sounds")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(darkBlue)
                Spacer()
                Button {
                    showUploadFlow = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            // Content based on step
            Group {
                switch uploadStep {
                case .pickFiles:
                    pickFilesStep
                case .namePack:
                    namePackStep
                case .done:
                    doneStep
                }
            }
        }
        .frame(width: 480, height: uploadStep == .pickFiles && !selectedFiles.isEmpty ? 480 : 340)
    }

    private var pickFilesStep: some View {
        VStack(spacing: 16) {
            Spacer()

            if selectedFiles.isEmpty {
                // Initial state — show requirements and pick button
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(orange.opacity(0.5))

                    Text("Select 5 to 10 MP3 files")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(darkBlue)

                    VStack(spacing: 4) {
                        Text("MP3 format only")
                        Text("Each sound: 10 seconds max")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.gray)
                }

                Button {
                    openFilePicker()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 14))
                        Text("Choose MP3 Files")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(orange))
                }
                .buttonStyle(.plain)
            } else {
                // Show selected files with validation
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(selectedFiles.enumerated()), id: \.offset) { index, url in
                            fileRow(url: url, index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                if !validationErrors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(validationErrors, id: \.self) { error in
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                HStack {
                    Button {
                        openFilePicker()
                    } label: {
                        Text("Choose Different Files")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(orange)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    let validCount = selectedFiles.filter { orchestrator.soundPackManager.validateAudioFile(at: $0).isValid }.count

                    Button {
                        uploadStep = .namePack
                    } label: {
                        Text("Next")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(validCount >= 5 ? orange : Color.gray))
                    }
                    .buttonStyle(.plain)
                    .disabled(validCount < 5)
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .padding(.bottom, 16)
    }

    private func fileRow(url: URL, index: Int) -> some View {
        let result = orchestrator.soundPackManager.validateAudioFile(at: url)
        let isValid = result.isValid

        return HStack(spacing: 10) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(isValid ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(darkBlue)
                    .lineLimit(1)

                if let error = result.errorMessage {
                    Text(error)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.red)
                } else if case .valid(let duration) = result {
                    Text("\(String(format: "%.1f", duration))s")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isValid ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
        )
    }

    private var namePackStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "character.textbox")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(orange.opacity(0.5))

            Text("What should this sound pack be called?")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(darkBlue)

            TextField("e.g. Funny Sounds", text: $packName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .frame(width: 260)
                .multilineTextAlignment(.center)

            if let error = createError {
                Text(error)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
            }

            HStack(spacing: 12) {
                Button {
                    uploadStep = .pickFiles
                } label: {
                    Text("Back")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.gray)
                }
                .buttonStyle(.plain)

                Button {
                    createSoundPack()
                } label: {
                    HStack(spacing: 6) {
                        if isCreating {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(isCreating ? "Creating..." : "Create Pack")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(packName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : orange))
                }
                .buttonStyle(.plain)
                .disabled(packName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
            }

            Spacer()
        }
        .padding(.bottom, 16)
    }

    private var doneStep: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(.green)

            Text("\"\(packName)\" has been created!")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(darkBlue)

            Text("\(selectedFiles.count) sounds added")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.gray)

            Button {
                orchestrator.settings.selectedSoundPack = packName
                showUploadFlow = false
            } label: {
                Text("Use This Pack")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(orange))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.bottom, 16)
    }

    // MARK: - Actions

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.title = "Select 5 to 10 MP3 sounds (10 seconds max each)"
        panel.allowedContentTypes = [.mp3]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return }

        let urls = Array(panel.urls.prefix(10))
        selectedFiles = urls

        // Validate and collect errors
        var errors: [String] = []
        let validFiles = urls.filter { orchestrator.soundPackManager.validateAudioFile(at: $0).isValid }

        if urls.count < 5 {
            errors.append("You need at least 5 sounds (selected \(urls.count))")
        }
        if validFiles.count < urls.count {
            let invalidCount = urls.count - validFiles.count
            errors.append("\(invalidCount) file\(invalidCount == 1 ? " doesn't" : "s don't") meet the requirements")
        }

        // Keep only valid files
        selectedFiles = urls
        validationErrors = errors
    }

    private func createSoundPack() {
        let trimmedName = packName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        // Check for duplicate names
        if orchestrator.soundPackManager.packs.contains(where: { $0.name == trimmedName }) {
            createError = "A pack named \"\(trimmedName)\" already exists"
            return
        }

        isCreating = true
        createError = nil

        // Only use valid files
        let validFiles = selectedFiles.filter { orchestrator.soundPackManager.validateAudioFile(at: $0).isValid }

        do {
            try orchestrator.soundPackManager.createPack(
                name: trimmedName,
                description: "Custom sound pack",
                mode: .random,
                sourceFiles: validFiles
            )
            selectedFiles = validFiles
            uploadStep = .done
        } catch {
            createError = error.localizedDescription
        }

        isCreating = false
    }

    private func resetUploadFlow() {
        selectedFiles = []
        validationErrors = []
        packName = ""
        uploadStep = .pickFiles
        isCreating = false
        createError = nil
    }

    // MARK: - Subviews

    private var volumeControl: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.gray)

                Slider(value: $orchestrator.settings.volume, in: 0...1)
                    .accentColor(orange)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.gray)

                Text("\(Int(orchestrator.settings.volume * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(darkBlue)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scale volume by slap force")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(darkBlue)
                    Text("Harder slaps play louder sounds")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.gray)
                }
                Spacer()
                Toggle("", isOn: $orchestrator.settings.scaleVolumeByForce)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }

    private func soundPackCard(_ pack: SoundPack) -> some View {
        let isSelected = orchestrator.settings.selectedSoundPack == pack.name
        let isHovered = hoveredPack == pack.name
        let isUserPack = orchestrator.soundPackManager.isUserPack(pack)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                orchestrator.settings.selectedSoundPack = pack.name
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? orange.opacity(0.15) : Color.gray.opacity(0.08))
                            .frame(width: 44, height: 44)

                        Image(systemName: packIcon(pack))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isSelected ? orange : .secondary)
                    }

                    Spacer()

                    if isUserPack {
                        Button {
                            showDeleteConfirm = pack.name
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(orange)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(darkBlue)

                    Text(pack.description)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.gray)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    Label("\(pack.files.count) sounds", systemImage: "waveform")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.gray)

                    if isUserPack {
                        Text("Custom")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(orange.opacity(0.12))
                            )
                    }

                    Spacer()

                    Button {
                        let previousPack = orchestrator.settings.selectedSoundPack
                        orchestrator.settings.selectedSoundPack = pack.name
                        orchestrator.testSlap()
                        orchestrator.settings.selectedSoundPack = previousPack
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(isSelected ? orange : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 10 : 6, y: isHovered ? 6 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? orange : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.25), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            hoveredPack = hovered ? pack.name : nil
        }
        .alert("Delete \"\(showDeleteConfirm ?? "")\"?", isPresented: Binding(
            get: { showDeleteConfirm != nil },
            set: { if !$0 { showDeleteConfirm = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let name = showDeleteConfirm {
                    orchestrator.soundPackManager.deletePack(named: name)
                    if orchestrator.settings.selectedSoundPack == name {
                        orchestrator.settings.selectedSoundPack = "Default"
                    }
                }
                showDeleteConfirm = nil
            }
            Button("Cancel", role: .cancel) {
                showDeleteConfirm = nil
            }
        } message: {
            Text("This will permanently remove the sound pack and all its sounds.")
        }
    }

    private func packIcon(_ pack: SoundPack) -> String {
        switch pack.name.lowercased() {
        case let n where n.contains("default"): return "hand.raised.fill"
        case let n where n.contains("cartoon"): return "theatermasks.fill"
        case let n where n.contains("bass"):    return "speaker.wave.3.fill"
        case let n where n.contains("drum"):    return "drum.fill"
        default: return "music.note"
        }
    }
}

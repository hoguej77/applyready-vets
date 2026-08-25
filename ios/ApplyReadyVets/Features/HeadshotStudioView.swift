import ImagePlayground
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// A private, review-first bridge to the system Image Playground experience.
/// It never uploads a source photo to the app's optional career service.
struct HeadshotStudioView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var generatedImage: UIImage?
    @State private var targetRole = ""
    @State private var presentation: HeadshotPresentation = .businessCasual
    @State private var showsFileImporter = false
    @State private var showsImagePlayground = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                headshotPreview

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    preferredItemEncoding: .compatible
                ) {
                    Label(
                        sourceImage == nil ? "Choose a source photo" : "Replace source photo",
                        systemImage: "person.crop.rectangle.badge.plus"
                    )
                }
                .disabled(isSaving)

                Button("Choose image from Files", systemImage: "folder") {
                    showsFileImporter = true
                }
                .disabled(isSaving)
            } header: {
                Text("Your source photo")
            } footer: {
                Text("Choose a clear, recent photo of yourself. It stays in protected app storage unless you explicitly share an image.")
            }

            Section("Career framing") {
                TextField("Target role", text: $targetRole)
                    .textContentType(.jobTitle)
                Picker("Presentation", selection: $presentation) {
                    ForEach(HeadshotPresentation.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
            }

            Section {
                if supportsImagePlayground {
                    Button {
                        showsImagePlayground = true
                    } label: {
                        Label("Create with Apple Intelligence", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Brand.navySurface)
                    .disabled(sourceImage == nil || isSaving)
                    .accessibilityHint("Opens the system Image Playground with your private source photo and career brief")
                } else {
                    Label(
                        "Image creation is unavailable on this device",
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(.secondary)
                    ShareLink(item: generationBrief) {
                        Label("Share your headshot brief", systemImage: "square.and.arrow.up")
                    }
                }
            } header: {
                Text("AI headshot")
            } footer: {
                Text("Image Playground creates a new image in a system-supported style. It is not a photographic retouch—review the result and use only an image that represents you accurately.")
            }

            if let generated = generatedImage {
                Section("Generated headshot") {
                    Image(uiImage: generated)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("Generated professional headshot")
                    if let url = PrivateImageStore.savedGeneratedHeadshotURL() {
                        ShareLink(item: url) {
                            Label("Share headshot", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button("Remove generated headshot", systemImage: "trash", role: .destructive) {
                        do {
                            try PrivateImageStore.removeGeneratedHeadshot()
                            generatedImage = nil
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }

            Section("Photo coach") {
                Label("Face a window or soft light", systemImage: "sun.max")
                Label("Use a calm, uncluttered background", systemImage: "rectangle.inset.filled")
                Label("Frame from chest to just above the head", systemImage: "viewfinder")
                Label("Keep your real appearance and review before publishing", systemImage: "checkmark.shield")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Headshot studio")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showsFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                if let url = urls.first {
                    importSourceImage(from: url)
                }
            case let .failure(error):
                errorMessage = "The image could not be selected: \(error.localizedDescription)"
            }
        }
        .onChange(of: selectedPhoto) { _, selection in
            guard let selection else { return }
            Task {
                await importSelectedPhoto(selection)
            }
        }
        .task {
            sourceImage = PrivateImageStore.savedHeadshotSource()
            generatedImage = PrivateImageStore.savedGeneratedHeadshot()
            if targetRole.isEmpty {
                targetRole = model.draft.profile.targetRole
            }
        }
        .imagePlaygroundSheet(
            isPresented: $showsImagePlayground,
            concept: generationBrief,
            sourceImage: sourceImage.map { Image(uiImage: $0) },
            onCompletion: { url in
                saveGeneratedHeadshot(from: url)
            },
            onCancellation: {}
        )
        .alert(
            "Headshot needs attention",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try another image.")
        }
    }

    @ViewBuilder
    private var headshotPreview: some View {
        if let source = sourceImage {
            HStack(spacing: 14) {
                Image(uiImage: source)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 86, height: 86)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                    }
                    .accessibilityLabel("Selected source photo")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Source photo ready")
                        .font(.headline)
                    Text("You control whether to create or share a generated version.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Button("Remove source photo", systemImage: "trash", role: .destructive) {
                do {
                    try PrivateImageStore.removeHeadshotSource()
                    sourceImage = nil
                    generatedImage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            ContentUnavailableView {
                Label("A better headshot starts with you", systemImage: "person.crop.circle.badge.plus")
            } description: {
                Text("Choose a photo and the system can help you create a polished career-ready version.")
            }
            .listRowBackground(Color.clear)
        }
    }

    private var effectiveRole: String {
        let role = targetRole.trimmingCharacters(in: .whitespacesAndNewlines)
        return role.isEmpty ? "career professional" : role
    }

    private var generationBrief: String {
        "Professional headshot for a \(effectiveRole). \(presentation.promptDetail) Chest-up portrait, calm approachable expression, soft balanced lighting, clean uncluttered background, and a polished but natural appearance. Preserve the source person’s identity. No text, logos, uniforms, watermarks, or dramatic visual effects."
    }

    @MainActor
    private func importSelectedPhoto(_ selection: PhotosPickerItem) async {
        isSaving = true
        defer {
            isSaving = false
            selectedPhoto = nil
        }
        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                throw PrivateImageStore.StoreError.imageUnreadable
            }
            sourceImage = try PrivateImageStore.saveHeadshotSource(data)
            generatedImage = nil
        } catch {
            errorMessage = "The selected photo could not be saved: \(error.localizedDescription)"
        }
    }

    private func importSourceImage(from url: URL) {
        isSaving = true
        defer { isSaving = false }
        let wasAccessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if wasAccessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            sourceImage = try PrivateImageStore.saveHeadshotSource(
                Data(contentsOf: url, options: [.mappedIfSafe])
            )
            generatedImage = nil
        } catch {
            errorMessage = "The chosen photo could not be saved: \(error.localizedDescription)"
        }
    }

    private func saveGeneratedHeadshot(from url: URL) {
        do {
            generatedImage = try PrivateImageStore.saveGeneratedHeadshot(from: url)
        } catch {
            errorMessage = "The generated headshot could not be saved: \(error.localizedDescription)"
        }
    }
}

private enum HeadshotPresentation: String, CaseIterable, Identifiable {
    case businessCasual
    case executive
    case healthcare
    case creative

    var id: String { rawValue }

    var label: String {
        switch self {
        case .businessCasual: "Business casual"
        case .executive: "Executive"
        case .healthcare: "Healthcare"
        case .creative: "Creative professional"
        }
    }

    var promptDetail: String {
        switch self {
        case .businessCasual:
            "Business-casual wardrobe appropriate for an office or operations role."
        case .executive:
            "Refined executive wardrobe appropriate for leadership roles."
        case .healthcare:
            "Clean, professional attire appropriate for a healthcare setting, without branded clothing."
        case .creative:
            "Modern professional wardrobe appropriate for a creative or technology role."
        }
    }
}

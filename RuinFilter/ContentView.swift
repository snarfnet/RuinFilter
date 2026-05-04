import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var filteredImage: UIImage?
    @State private var selectedStyle: String = "abandoned"
    @State private var showComparison = false
    @State private var isProcessing = false
    @State private var showSaved = false
    @State private var useCamera = false

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Image display
                        imageSection

                        // Photo picker buttons
                        if originalImage == nil {
                            pickSection
                        }

                        // Style selector
                        if originalImage != nil {
                            styleSelector
                            actionButtons
                        }

                        Spacer(minLength: 60)
                    }
                    .padding()
                }
                .navigationTitle("廃墟フィルター")
                .background(Color(.systemGroupedBackground))
            }

            BannerAdView(adUnitID: "ca-app-pub-9404799280370656/7738213773")
                .frame(height: 50)
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedItem) { newItem in
            loadImage(from: newItem)
        }
        .fullScreenCover(isPresented: $useCamera) {
            CameraView(image: $originalImage)
                .ignoresSafeArea()
        }
        .onChange(of: originalImage) { _ in
            applyFilter()
        }
        .overlay {
            if showSaved {
                savedToast
            }
        }
    }

    // MARK: - Image Section
    private var imageSection: some View {
        ZStack {
            if let image = showComparison ? originalImage : filteredImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        Text(showComparison ? "BEFORE" : "AFTER")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(8)
                    }
                    .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                        showComparison = pressing
                    }, perform: {})
            } else if originalImage != nil {
                ProgressView()
                    .frame(height: 300)
            } else {
                placeholderView
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showComparison)
    }

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .brown], startPoint: .top, endPoint: .bottom)
                )
            Text("写真を選んで廃墟に変えよう")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Long press to compare before/after")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Pick Section
    private var pickSection: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("写真を選ぶ", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [.orange, .brown], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
            }

            Button {
                useCamera = true
            } label: {
                Label("撮影", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(14)
            }
        }
    }

    // MARK: - Style Selector
    private var styleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("フィルター")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RuinFilterEngine.styles) { style in
                        Button {
                            selectedStyle = style.id
                            applyFilter()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: style.icon)
                                    .font(.title2)
                                Text(style.name)
                                    .font(.caption)
                            }
                            .frame(width: 70, height: 70)
                            .background(selectedStyle == style.id ? Color.orange : Color(.systemGray5))
                            .foregroundColor(selectedStyle == style.id ? .white : .primary)
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                saveImage()
            } label: {
                Label("保存", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(14)
            }
            .disabled(filteredImage == nil)

            if let image = filteredImage {
                ShareLink(item: Image(uiImage: image), preview: SharePreview("廃墟フィルター", image: Image(uiImage: image))) {
                    Label("共有", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(.systemGray3))
                        .cornerRadius(14)
                }
            }

            Button {
                originalImage = nil
                filteredImage = nil
                selectedItem = nil
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(.systemGray3))
                    .cornerRadius(14)
            }
        }
    }

    // MARK: - Toast
    private var savedToast: some View {
        VStack {
            Spacer()
            Text("保存しました")
                .font(.headline)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.bottom, 80)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Logic
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        item.loadTransferable(type: Data.self) { result in
            if case .success(let data) = result, let data, let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    originalImage = img
                }
            }
        }
    }

    private func applyFilter() {
        guard let original = originalImage else { return }
        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            let ciImage = CIImage(image: original)!
            let style = RuinFilterEngine.styles.first { $0.id == selectedStyle } ?? RuinFilterEngine.styles[0]

            if let filtered = style.apply(ciImage),
               let result = RuinFilterEngine.render(filtered) {
                DispatchQueue.main.async {
                    filteredImage = result
                    isProcessing = false
                }
            }
        }
    }

    private func saveImage() {
        guard let image = filteredImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        withAnimation {
            showSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaved = false
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

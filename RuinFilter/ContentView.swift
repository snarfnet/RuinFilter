import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var filteredImage: UIImage?
    @State private var selectedStyle: String = "haunted"
    @State private var showComparison = false
    @State private var isProcessing = false
    @State private var showSaved = false
    @State private var useCamera = false

    var body: some View {
        ZStack(alignment: .bottom) {
            RuinTheme.background.ignoresSafeArea()
            RuinMist()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            NavigationStack {
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        imageSection

                        if originalImage == nil {
                            pickSection
                            horrorNotes
                        } else {
                            styleSelector
                            actionButtons
                            compareHint
                        }

                        Spacer(minLength: AppRuntime.showsAds ? 76 : 24)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
            }

            if AppRuntime.showsAds {
                BannerAdView(adUnitID: "ca-app-pub-9404799280370656/7738213773")
                    .frame(height: 50)
                    .background(.black.opacity(0.8))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: prepareScreenshotStateIfNeeded)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("廃墟フィルター")
                        .font(.system(size: 34, weight: .black, design: .serif))
                        .foregroundStyle(RuinTheme.titleGradient)
                        .shadow(color: .red.opacity(0.45), radius: 18, x: 0, y: 0)

                    Text("写真を、誰も帰ってこない廃墟の記録へ。")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer()

                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.92))
                    .padding(12)
                    .background(RuinTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.red.opacity(0.35), lineWidth: 1))
            }

            HStack(spacing: 8) {
                Label("暗室補正", systemImage: "camera.filters")
                Label("ノイズ", systemImage: "waveform.path.ecg")
                Label("呪い", systemImage: "moon.haze.fill")
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var imageSection: some View {
        ZStack {
            if let image = showComparison ? originalImage : filteredImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: AppRuntime.isScreenshotMode ? 430 : 380)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(RuinTheme.blood.opacity(0.75), lineWidth: 1.4))
                    .overlay(alignment: .topLeading) {
                        Text(showComparison ? "BEFORE" : selectedStyleLabel)
                            .font(.system(size: 13, weight: .black))
                            .tracking(1.8)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(.black.opacity(0.72))
                            .foregroundStyle(showComparison ? .white : RuinTheme.warning)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(10)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if isProcessing {
                            ProgressView()
                                .tint(RuinTheme.warning)
                                .padding(12)
                                .background(.black.opacity(0.7))
                                .clipShape(Circle())
                                .padding(12)
                        }
                    }
                    .shadow(color: .black.opacity(0.8), radius: 28, x: 0, y: 20)
                    .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                        showComparison = pressing
                    }, perform: {})
            } else if originalImage != nil {
                ProgressView("変換中...")
                    .font(.headline)
                    .tint(RuinTheme.warning)
                    .frame(height: 340)
                    .frame(maxWidth: .infinity)
                    .background(RuinTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                placeholderView
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showComparison)
        .animation(.easeInOut(duration: 0.2), value: filteredImage)
    }

    private var placeholderView: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(.red.opacity(0.14))
                    .frame(width: 132, height: 132)
                    .blur(radius: 10)
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(RuinTheme.titleGradient)
                    .shadow(color: .red.opacity(0.55), radius: 18)
            }

            VStack(spacing: 8) {
                Text("写真を選ぶと、廃墟化が始まります")
                    .font(.system(size: 21, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Text("暗い縁取り、古い粒子、冷たい色、赤い警告光でホラー寄りに変換します。")
                    .font(.system(size: 15, weight: .medium))
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.68))
                    .padding(.horizontal, 8)
            }
        }
        .frame(height: 360)
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(RuinTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
        .overlay(alignment: .topTrailing) {
            Text("NO SIGNAL")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(RuinTheme.blood)
                .padding(10)
        }
    }

    private var pickSection: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                RuinActionLabel(title: "写真を選ぶ", icon: "photo.on.rectangle.angled", primary: true)
            }

            Button {
                useCamera = true
            } label: {
                RuinActionLabel(title: "撮影", icon: "camera.fill", primary: false)
            }
        }
    }

    private var horrorNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            RuinNote(icon: "hand.raised.fill", title: "長押しで比較", text: "変換後の画像を押している間だけ元写真に戻ります。")
            RuinNote(icon: "exclamationmark.triangle.fill", title: "暗めに強化", text: "今回の版では文字を大きくし、操作面も見やすくしました。")
        }
    }

    private var styleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("廃墟スタイル")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RuinFilterEngine.styles) { style in
                        Button {
                            selectedStyle = style.id
                            applyFilter()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 24, weight: .bold))
                                Text(style.name)
                                    .font(.system(size: 14, weight: .heavy))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }
                            .frame(width: 96, height: 88)
                            .background(selectedStyle == style.id ? RuinTheme.selectedPanel : RuinTheme.panel)
                            .foregroundStyle(selectedStyle == style.id ? RuinTheme.warning : .white.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedStyle == style.id ? RuinTheme.warning.opacity(0.85) : .white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                saveImage()
            } label: {
                RuinActionLabel(title: "保存", icon: "square.and.arrow.down.fill", primary: true)
            }
            .disabled(filteredImage == nil)

            ShareLink(item: "廃墟フィルターで写真を変換しました") {
                RuinActionLabel(title: "共有", icon: "square.and.arrow.up.fill", primary: false)
            }

            Button {
                originalImage = nil
                filteredImage = nil
                selectedItem = nil
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(RuinTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 1))
            }
        }
    }

    private var compareHint: some View {
        Text("画像を長押しすると変換前を確認できます")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.62))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var savedToast: some View {
        VStack {
            Spacer()
            Label("写真に保存しました", systemImage: "checkmark.seal.fill")
                .font(.system(size: 17, weight: .heavy))
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.black.opacity(0.88))
                .foregroundStyle(RuinTheme.warning)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RuinTheme.warning.opacity(0.45), lineWidth: 1))
                .padding(.bottom, 88)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var selectedStyleLabel: String {
        RuinFilterEngine.styles.first { $0.id == selectedStyle }?.nameEn.uppercased() ?? "AFTER"
    }

    private func prepareScreenshotStateIfNeeded() {
        guard AppRuntime.isScreenshotMode else { return }
        let sample = RuinFilterEngine.makeSampleRuinImage()
        originalImage = sample
        filteredImage = sample

        switch AppRuntime.screenshotScreen {
        case "home":
            originalImage = nil
            filteredImage = nil
        case "editor":
            selectedStyle = "haunted"
            originalImage = sample
            filteredImage = sample
        case "result":
            selectedStyle = "nightmare"
            originalImage = sample
            filteredImage = sample
        default:
            selectedStyle = "haunted"
        }
        if originalImage != nil {
            applyFilter()
        }
    }

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
            guard let ciImage = CIImage(image: original) else { return }
            let style = RuinFilterEngine.styles.first { $0.id == selectedStyle } ?? RuinFilterEngine.styles[0]

            if let filtered = style.apply(ciImage),
               let result = RuinFilterEngine.render(filtered, orientation: original.imageOrientation) {
                DispatchQueue.main.async {
                    filteredImage = result
                    isProcessing = false
                }
            } else {
                DispatchQueue.main.async {
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

private struct RuinActionLabel: View {
    let title: String
    let icon: String
    let primary: Bool

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 17, weight: .black))
            .foregroundStyle(primary ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(primary ? RuinTheme.warning : Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(primary ? .black.opacity(0.35) : .white.opacity(0.12), lineWidth: 1))
    }
}

private struct RuinNote: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(RuinTheme.warning)
                .frame(width: 36, height: 36)
                .background(.black.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }
            Spacer()
        }
        .padding(13)
        .background(RuinTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private enum RuinTheme {
    static let blood = Color(red: 0.82, green: 0.03, blue: 0.06)
    static let warning = Color(red: 0.92, green: 0.83, blue: 0.55)

    static let background = LinearGradient(
        colors: [
            Color(red: 0.015, green: 0.012, blue: 0.014),
            Color(red: 0.055, green: 0.018, blue: 0.022),
            Color(red: 0.018, green: 0.022, blue: 0.024)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panel = LinearGradient(
        colors: [Color.white.opacity(0.09), Color.black.opacity(0.34)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let selectedPanel = LinearGradient(
        colors: [blood.opacity(0.42), Color.black.opacity(0.55)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let titleGradient = LinearGradient(
        colors: [warning, Color(red: 0.72, green: 0.06, blue: 0.08)],
        startPoint: .top,
        endPoint: .bottom
    )
}

private struct RuinMist: View {
    var body: some View {
        Canvas { context, size in
            for i in 0..<18 {
                let x = CGFloat((i * 97) % 360) / 360 * size.width
                let y = CGFloat((i * 53) % 260) / 260 * size.height
                let rect = CGRect(x: x - 90, y: y - 26, width: 180, height: 52)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(i.isMultiple(of: 3) ? .red.opacity(0.035) : .white.opacity(0.026))
                )
            }
        }
        .blur(radius: 18)
        .blendMode(.screen)
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

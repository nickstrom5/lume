import SwiftUI
import UIKit

struct FirstScanView: View {
    @Environment(LumeStore.self) private var store
    @State private var camera = false

    var body: some View {
        DuoLayout {
            FacePane(image: UIImage(named: "still"), caption: "Same window. Same hour.")
        } secondary: {
            VStack(alignment: .leading, spacing: 16) {
                Wordmark { store.seedForReview() }
                    .padding(.top, 8)
                Kicker(text: "First reading")
                Text("Take the photo you will take tomorrow.")
                    .font(.display(32))
                    .foregroundStyle(LumeTheme.fg)
                Text("Front camera, indoor daylight, no filter. Lume reads it on this device. The picture is not uploaded.")
                    .font(.system(size: 15))
                    .foregroundStyle(LumeTheme.muted)
                    .lineSpacing(4)
                Spacer()
                LumeButton(title: "Open camera") { camera = true }
                LumeButton(title: "Use a sample photo", fill: false) {
                    if let img = UIImage(named: "scan-a") ?? UIImage(named: "still") {
                        store.ingest(image: img, name: "scan-a")
                    }
                }
            }
            .padding(20)
            .background(LumeTheme.bg)
            .fullScreenCover(isPresented: $camera) {
                CameraPicker { image in
                    camera = false
                    if let image { store.ingest(image: image) }
                }
                .ignoresSafeArea()
            }
        }
    }
}

struct AnalyzingView: View {
    @Environment(LumeStore.self) private var store

    var body: some View {
        DuoLayout {
            FacePane(image: store.pendingScan.flatMap { store.thumb(for: $0.thumbName) }, caption: "Reading the map")
        } secondary: {
            VStack(spacing: 24) {
                Spacer()
                ProgressView()
                    .tint(LumeTheme.accent)
                    .scaleEffect(1.4)
                Text("Reading glow, evenness, texture, calm.")
                    .font(.display(28))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LumeTheme.fg)
                    .padding(.horizontal, 24)
                Text("On this device. Not a diagnosis.")
                    .font(.system(size: 14))
                    .foregroundStyle(LumeTheme.muted)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LumeTheme.bg)
        }
    }
}

struct RevealView: View {
    @Environment(LumeStore.self) private var store
    @Environment(PlusStore.self) private var plus

    var body: some View {
        let scan = store.pendingScan
        DuoLayout {
            FacePane(
                image: scan.flatMap { store.thumb(for: $0.thumbName) },
                caption: scan.map { "\($0.scores.overall) · \(scoreLabel($0.scores.overall))" } ?? "Your reading"
            )
        } secondary: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Wordmark { store.seedForReview() }
                    Kicker(text: "Your map")
                    Text("This is the baseline.")
                        .font(.display(32))
                        .foregroundStyle(LumeTheme.fg)
                    if let scan {
                        ScoreRing(value: scan.scores.overall, size: 140)
                            .frame(maxWidth: .infinity)
                        metricRow("Glow", scan.scores.glow)
                        metricRow("Evenness", scan.scores.evenness)
                        metricRow("Texture", scan.scores.texture)
                        metricRow("Calm", scan.scores.calm)
                        ForEach(scan.insights, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 15))
                                .foregroundStyle(LumeTheme.muted)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(LumeTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        Text(scan.focus)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(LumeTheme.fg)
                    }
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                LumeButton(title: plus.isPlus ? "Open today" : "Unlock the ritual") {
                    if plus.isPlus {
                        store.startTrial()
                    } else {
                        store.goPaywall()
                    }
                }
                .padding(20)
                .background(LumeTheme.bg)
            }
            .background(LumeTheme.bg)
        }
    }

    private func metricRow(_ label: String, _ n: Int) -> some View {
        HStack {
            Text(label).foregroundStyle(LumeTheme.muted)
            Spacer()
            Text("\(n)").font(.system(size: 16, weight: .semibold, design: .rounded))
        }
        .font(.system(size: 15))
        .foregroundStyle(LumeTheme.fg)
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onFinish: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraDevice = .front
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onFinish: (UIImage?) -> Void
        init(onFinish: @escaping (UIImage?) -> Void) { self.onFinish = onFinish }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onFinish(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onFinish(info[.originalImage] as? UIImage)
        }
    }
}

import SwiftUI
import UIKit

// MARK: - CameraPickerView

/// SwiftUI wrapper around `UIImagePickerController` for live camera capture.
///
/// On a physical device it opens the camera. On Simulator (no camera hardware)
/// it falls back to the photo library so previews keep working.
///
/// Usage:
/// ```swift
/// CameraPickerView(mode: .photoAndVideo) { data, isVideo in
///     // handle captured media
/// } onCancel: {
///     // dismissed without capture
/// }
/// ```
struct CameraPickerView: UIViewControllerRepresentable {

    enum CaptureMode {
        case photo
        case video
        case photoAndVideo
    }

    let mode: CaptureMode
    var onCapture: (Data, Bool) -> Void   // (data, isVideo)
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            switch mode {
            case .photo:
                picker.mediaTypes = ["public.image"]
                picker.cameraCaptureMode = .photo
            case .video:
                picker.mediaTypes = ["public.movie"]
                picker.cameraCaptureMode = .video
                picker.videoQuality = .typeMedium
            case .photoAndVideo:
                picker.mediaTypes = ["public.image", "public.movie"]
                picker.cameraCaptureMode = .photo
                picker.videoQuality = .typeMedium
            }
        } else {
            // Simulator fallback — use photo library
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.image", "public.movie"]
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (Data, Bool) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (Data, Bool) -> Void,
             onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let videoURL = info[.mediaURL] as? URL,
               let videoData = try? Data(contentsOf: videoURL) {
                onCapture(videoData, true)
                return
            }
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                onCapture(imageData, false)
                return
            }
            onCancel()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

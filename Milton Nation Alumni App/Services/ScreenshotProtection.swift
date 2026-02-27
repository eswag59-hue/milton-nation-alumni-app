import SwiftUI
import UIKit

extension View {
    /// Prevents this view and all subviews from appearing in screenshots,
    /// screen recordings, AirPlay mirrors, or QuickTime captures.
    /// The OS renders the protected area as solid black in any capture.
    func screenshotProtected() -> some View {
        modifier(ScreenshotProtectionModifier())
    }
}

// MARK: - Modifier

private struct ScreenshotProtectionModifier: ViewModifier {
    func body(content: Content) -> some View {
        ScreenshotProtectionRepresentable {
            content
        }
        .ignoresSafeArea()
    }
}

// MARK: - UIViewControllerRepresentable Bridge

/// Bridges SwiftUI content into a UIKit hierarchy where
/// UITextField's secure container provides OS-level capture blocking.
private struct ScreenshotProtectionRepresentable<Content: View>: UIViewControllerRepresentable {
    @ViewBuilder let content: Content

    func makeUIViewController(context: Context) -> ScreenshotProtectionViewController<Content> {
        ScreenshotProtectionViewController(rootView: content)
    }

    func updateUIViewController(
        _ vc: ScreenshotProtectionViewController<Content>,
        context: Context
    ) {
        vc.hostingController.rootView = content
    }
}

// MARK: - View Controller

/// Embeds SwiftUI content inside a UITextField's private secure container.
/// The system automatically blacks out anything inside this container
/// in screenshots, screen recordings, and screen mirrors.
final class ScreenshotProtectionViewController<Content: View>: UIViewController {

    let hostingController: UIHostingController<Content>
    private let secureTextField = UITextField()

    init(rootView: Content) {
        self.hostingController = UIHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupSecureContainer()
    }

    private func setupSecureContainer() {
        // A UITextField with isSecureTextEntry=true has a private system subview
        // that the OS uses to prevent its content from being captured.
        // We exploit this by embedding our SwiftUI content inside it.
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.backgroundColor = .clear
        secureTextField.frame = view.bounds
        secureTextField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(secureTextField)

        // The first (and only) subview is the OS secure container.
        guard let secureContainer = secureTextField.subviews.first else {
            // Fallback: add content directly if secure container not found
            embedHostingController(in: view)
            return
        }

        secureContainer.isUserInteractionEnabled = true
        embedHostingController(in: secureContainer)
    }

    private func embedHostingController(in container: UIView) {
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        container.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: container.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        hostingController.didMove(toParent: self)
    }
}

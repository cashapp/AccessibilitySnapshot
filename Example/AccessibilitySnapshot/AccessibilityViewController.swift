import AccessibilitySnapshotCore
import UIKit

/// A view controller that displays zoomable content with a close button
private class ZoomableOverlayViewController: UIViewController, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private var contentView: UIView?
    var onClose: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupCloseButton()
    }

    func configure(with contentView: UIView) {
        self.contentView = contentView

        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.layer.shadowOpacity = 0.25
        contentView.layer.shadowRadius = 12

        scrollView.addSubview(contentView)
    }

    func configureZoom() {
        guard let contentView = contentView else { return }

        view.frame = UIScreen.main.bounds
        view.layoutIfNeeded()

        let widthScale = scrollView.bounds.width / contentView.bounds.width
        let heightScale = scrollView.bounds.height / contentView.bounds.height
        let initialScale = min(widthScale, heightScale, 1.0)

        scrollView.minimumZoomScale = min(initialScale, 0.5)
        scrollView.maximumZoomScale = 3.0
        scrollView.zoomScale = initialScale
    }

    // MARK: - Private Setup

    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.backgroundColor = .systemGray6
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
    }

    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        closeButton.backgroundColor = .systemBackground
        closeButton.layer.cornerRadius = 8
        closeButton.layer.shadowColor = UIColor.black.cgColor
        closeButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        closeButton.layer.shadowOpacity = 0.15
        closeButton.layer.shadowRadius = 4
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        onClose?()
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: contentView)
            let zoomScale = min(scrollView.maximumZoomScale, scrollView.minimumZoomScale * 2.0)
            let size = scrollView.bounds.size
            let rect = CGRect(
                x: location.x - size.width / zoomScale / 2,
                y: location.y - size.height / zoomScale / 2,
                width: size.width / zoomScale,
                height: size.height / zoomScale
            )
            scrollView.zoom(to: rect, animated: true)
        }
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let contentView = contentView else { return }

        let offsetX = max((scrollView.bounds.width - contentView.frame.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - contentView.frame.height) / 2, 0)

        contentView.center = CGPoint(
            x: contentView.frame.width / 2 + offsetX,
            y: contentView.frame.height / 2 + offsetY
        )
    }
}

/// A view controller that toggles accessibility overlay/legend on shake gesture.
/// Shake twice quickly to display/dismiss the view controller.
class AccessibilityViewController: UIViewController {
    // MARK: - Private Properties

    private var accessibilityOverlayViewController: UIViewController?
    private var lastShakeTime: Date?
    private var isShakeInProgress = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake, !isShakeInProgress else { return }

        let now = Date()

        // Check for double shake (two shakes within 0.5 seconds) to dismiss
        if let lastShake = lastShakeTime, now.timeIntervalSince(lastShake) < 0.5 {
            hideAccessibilityOverlay()
            return
        }

        lastShakeTime = now
        isShakeInProgress = true

        if accessibilityOverlayViewController != nil {
            hideAccessibilityOverlay()
        } else {
            showAccessibilityOverlay()
        }
    }

    // MARK: - Private Methods

    private func showAccessibilityOverlay() {
        let snapshotView = AccessibilitySnapshotView(
            containedView: view,
            snapshotConfiguration: AccessibilitySnapshotConfiguration(viewRenderingMode: .drawHierarchyInRect)
        )

        do {
            try snapshotView.parseAccessibility()
        } catch {
            print("❌ Failed to parse accessibility: \(error)")
            isShakeInProgress = false
            showAlert(title: "Error", message: "Failed to parse accessibility overlay. See console for details.")
            return
        }

        snapshotView.sizeToFit()

        let overlayVC = ZoomableOverlayViewController()
        overlayVC.modalPresentationStyle = .overFullScreen
        overlayVC.modalTransitionStyle = .coverVertical
        overlayVC.configure(with: snapshotView)
        overlayVC.configureZoom()
        overlayVC.onClose = { [weak self] in
            self?.hideAccessibilityOverlay()
        }

        accessibilityOverlayViewController = overlayVC
        present(overlayVC, animated: true) { [weak self] in
            self?.isShakeInProgress = false
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func hideAccessibilityOverlay() {
        accessibilityOverlayViewController?.dismiss(animated: true) { [weak self] in
            self?.accessibilityOverlayViewController = nil
            self?.isShakeInProgress = false
        }
    }
}

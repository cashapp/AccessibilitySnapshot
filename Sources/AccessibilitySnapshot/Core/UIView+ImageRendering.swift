import CoreImage
import UIKit

public enum ImageRenderingError: Swift.Error {
    /// An error indicating that the `containedView` is too large too snapshot using the specified rendering
    /// parameters.
    ///
    /// - Note: This error is thrown due to filters failing. To avoid this error, try rendering the snapshot in
    /// polychrome, reducing the size of the `containedView`, or running on a different iOS version. In particular,
    /// this error is known to occur when rendering a monochrome snapshot on iOS 13.
    case containedViewExceedsMaximumSize(viewSize: CGSize, maximumSize: CGSize)

    /// An error indicating that the `containedView` has a transform that is not support while using the specified
    /// rendering parameters.
    ///
    /// - Note: In particular, this error is known to occur when using a non-identity transform that requires
    /// tiling. To avoid this error, try setting an identity transform on the `containedView` or using the
    /// `.renderLayerInContext` view rendering mode
    case containedViewHasUnsupportedTransform(transform: CATransform3D)

    /// An error indicating the `containedView` has an invalid size due to the `width` and/or `height` being zero.
    case containedViewHasZeroSize(viewSize: CGSize)

    /// An error indicating that the `containedView`'s safe area could not be preserved while rendering the snapshot
    /// in tiles, so the tiled snapshot would not match the view's original appearance.
    ///
    /// Rendering a view large enough to require tiling temporarily restructures the view hierarchy around it. If the
    /// view's safe area cannot be restored to its original value in the temporary hierarchy, any layout driven by the
    /// safe area would shift relative to where the view's accessibility elements were parsed, producing misaligned
    /// overlays. This error is thrown instead of silently rendering the shifted content. To avoid this error, try
    /// using the `.renderLayerInContext` view rendering mode, which does not require tiling.
    case containedViewSafeAreaCouldNotBePreserved(
        originalSafeAreaInsets: UIEdgeInsets,
        currentSafeAreaInsets: UIEdgeInsets
    )
}

extension UIView {
    @available(*, deprecated, message: "Please use `renderToImage(configuration:)` instead.")
    public func renderToImage(
        monochrome: Bool,
        viewRenderingMode: ViewRenderingMode
    ) throws -> UIImage {
        let config = AccessibilitySnapshotConfiguration.Rendering(renderMode: viewRenderingMode, colorMode: monochrome ? .monochrome : .fullColor)
        return try renderToImage(configuration: config)
    }

    public func renderToImage(
        configuration: AccessibilitySnapshotConfiguration.Rendering
    ) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)

        // Hide the cursor of text inputs to prevent test flakes.
        var viewTintsToRestore: [UIView: UIColor] = [:]
        recursiveForEach(viewType: UITextField.self) { inputView in
            viewTintsToRestore[inputView] = inputView.tintColor
            inputView.tintColor = .clear
        }
        recursiveForEach(viewType: UITextView.self) { inputView in
            viewTintsToRestore[inputView] = inputView.tintColor
            inputView.tintColor = .clear
        }
        defer {
            viewTintsToRestore.forEach { inputView, tintColor in
                inputView.tintColor = tintColor
            }
        }

        var error: Error?

        let snapshot = renderer.image { context in
            switch configuration.renderMode {
            case .drawHierarchyInRect:
                if bounds.width > UIView.tileSideLength || bounds.height > UIView.tileSideLength {
                    drawTiledHierarchySnapshots(in: context, error: &error)
                } else {
                    drawHierarchy(in: bounds, afterScreenUpdates: true)
                }

            case .renderLayerInContext:
                layer.render(in: context.cgContext)
            }
        }

        if let error = error {
            throw error
        }

        if configuration.colorMode == .monochrome {
            return try monochromeSnapshot(for: snapshot) ?? snapshot

        } else {
            return snapshot
        }
    }

    private func monochromeSnapshot(for snapshot: UIImage) throws -> UIImage? {
        if ProcessInfo().operatingSystemVersion.majorVersion == 13 {
            // On iOS 13, the image filter silently fails for large images, "successfully" producing a blank output
            // image. From testing, the maximum support size is 1365x1365 pt. Exceeding that in either dimension will
            // result in a blank image.
            let maximumSize = CGSize(width: 1365, height: 1365)
            if snapshot.size.width > maximumSize.width || snapshot.size.height > maximumSize.height {
                throw ImageRenderingError.containedViewExceedsMaximumSize(
                    viewSize: snapshot.size,
                    maximumSize: maximumSize
                )
            }
        }

        guard let inputImage = CIImage(image: snapshot) else {
            return nil
        }

        let monochromeFilter = CIFilter(
            name: "CIColorControls",
            parameters: [
                kCIInputImageKey: inputImage,
                kCIInputSaturationKey: 0,
            ]
        )!

        let context = CIContext()

        guard
            let outputImage = monochromeFilter.outputImage,
            let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func drawTiledHierarchySnapshots(in context: UIGraphicsImageRendererContext, error: inout Error?) {
        guard CATransform3DIsIdentity(layer.transform) else {
            error = ImageRenderingError.containedViewHasUnsupportedTransform(transform: layer.transform)
            return
        }

        let originalSafeAreaInsets = safeAreaInsets

        // A view's safe area is governed by the nearest view controller in its responder chain: changes to a plain
        // view's geometry or ancestry do not reliably invalidate its safe area, and a view controller's
        // `additionalSafeAreaInsets` only affect the views it manages. Capture the view's own view controller if it
        // has one, or adopt the view into a temporary view controller otherwise, so that the safe area can be
        // restored below through a controller that actually governs this view.
        let adoptingViewController: UIViewController?
        let governingViewController: UIViewController
        if let owningViewController = next as? UIViewController {
            adoptingViewController = nil
            governingViewController = owningViewController
        } else {
            let viewController = UIViewController()
            viewController.view = self
            adoptingViewController = viewController
            governingViewController = viewController
        }

        let originalAdditionalSafeAreaInsets = governingViewController.additionalSafeAreaInsets
        defer {
            governingViewController.additionalSafeAreaInsets = originalAdditionalSafeAreaInsets

            // Detach the view from the temporary view controller by giving the controller a new view, restoring the
            // view's original responder chain. Installing the controller's new root view also removes this view from
            // its superview, and this defer runs after the superview restoration below, so re-add the view to keep
            // the restored hierarchy intact. Otherwise the accessibility parse that follows would run on a windowless
            // view, where every accessibility frame resolves to zero and the overlay markers collapse to nothing.
            if let adoptingViewController {
                let superviewBeforeDetach = superview
                adoptingViewController.view = UIView()
                if superview == nil, let superviewBeforeDetach {
                    superviewBeforeDetach.addSubview(self)
                }
            }
        }

        let originalSuperview = superview
        let originalOrigin = frame.origin
        let originalAutoresizingMask = autoresizingMask
        defer {
            originalSuperview?.addSubview(self)
            frame.origin = originalOrigin
            autoresizingMask = originalAutoresizingMask
        }

        let frameView = UIView(frame: frame)
        originalSuperview?.addSubview(frameView)
        defer {
            frameView.removeFromSuperview()
        }

        autoresizingMask = []
        frame.origin = .zero

        let containerView = UIView(frame: frame)
        containerView.autoresizingMask = []
        containerView.addSubview(self)
        frameView.addSubview(containerView)

        // Run the run loop for one cycle so that the layout changes caused by restructuring the view hierarchy are
        // propagated.
        RunLoop.current.run(until: Date())

        // Reparenting the view can leave its safe area stale: UIKit zeroes the safe area when the view is removed
        // from its superview and does not recompute it in the new hierarchy until something invalidates it. Toggling
        // the governing view controller's additional safe area insets forces that recomputation, after which the safe
        // area resolves to its original value on its own.
        var nudgedSafeAreaInsets = originalAdditionalSafeAreaInsets
        nudgedSafeAreaInsets.top += 1
        governingViewController.additionalSafeAreaInsets = nudgedSafeAreaInsets
        governingViewController.additionalSafeAreaInsets = originalAdditionalSafeAreaInsets
        RunLoop.current.run(until: Date())

        // If the safe area could not be restored, any safe-area-driven layout in the view would render shifted
        // relative to the accessibility elements parsed from the original hierarchy. Fail loudly rather than
        // producing a snapshot with misaligned content.
        guard safeAreaInsets == originalSafeAreaInsets else {
            error = ImageRenderingError.containedViewSafeAreaCouldNotBePreserved(
                originalSafeAreaInsets: originalSafeAreaInsets,
                currentSafeAreaInsets: safeAreaInsets
            )
            return
        }

        let bounds = self.bounds
        var tileRect: CGRect = .zero

        while tileRect.minY < bounds.maxY {
            tileRect.origin.x = bounds.minX
            tileRect.size.height = min(tileRect.minY + UIView.tileSideLength, bounds.maxY) - tileRect.minY

            while tileRect.minX < bounds.maxX {
                tileRect.size.width = min(tileRect.minX + UIView.tileSideLength, bounds.maxX) - tileRect.minX
                frameView.frame.size = tileRect.size

                // Move the origin of the `frameView` and `containerView` such that the frame is over the right area of
                // the snapshotted view, but the snapshotted view stays fixed relative to the `frameView`'s superview
                // (so the view's position on screen doesn't change).
                frameView.frame.origin = CGPoint(x: tileRect.minX, y: tileRect.minY)
                containerView.frame.origin = CGPoint(x: -tileRect.minX, y: -tileRect.minY)

                UIGraphicsImageRenderer(bounds: frameView.bounds)
                    .image { _ in
                        frameView.drawHierarchy(in: frameView.bounds, afterScreenUpdates: true)
                    }
                    .draw(at: tileRect.origin)

                tileRect.origin.x += UIView.tileSideLength
            }

            tileRect.origin.y += UIView.tileSideLength
        }
    }

    private static let tileSideLength: CGFloat = 2000

    private func recursiveForEach<ViewType: UIView>(
        viewType: ViewType.Type,
        _ block: (ViewType) -> Void
    ) {
        if let view = self as? ViewType {
            block(view)
        }
        subviews.forEach { $0.recursiveForEach(viewType: viewType, block) }
    }
}

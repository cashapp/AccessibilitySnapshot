//
//  Copyright 2023 Block Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

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

}

extension UIView {

    func renderToImage(
        monochrome: Bool,
        viewRenderingMode: AccessibilitySnapshotView.ViewRenderingMode
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
            switch viewRenderingMode {
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

        if monochrome {
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

        let originalSafeArea = bounds.inset(by: safeAreaInsets)

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

        let containerViewController = UIViewController()
        let containerView = containerViewController.view!
        containerView.frame = frame
        containerView.autoresizingMask = []
        containerView.addSubview(self)
        frameView.addSubview(containerView)

        // Run the run loop for one cycle so that the safe area changes caused by restructuring the view hierarhcy are
        // propogated. Then calculate the required additional safe area insets to create the equivalent original safe
        // area. This new change will be propogated automatically when we draw the hierarchy for the first time.
        RunLoop.current.run(until: Date())
        let currentSafeArea = containerView.convert(bounds.inset(by: safeAreaInsets), from: self)
        containerViewController.additionalSafeAreaInsets = UIEdgeInsets(
            top: originalSafeArea.minY - currentSafeArea.minY,
            left: originalSafeArea.minX - currentSafeArea.minX,
            bottom: currentSafeArea.maxY - originalSafeArea.maxY,
            right: currentSafeArea.maxX - originalSafeArea.maxX
        )

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

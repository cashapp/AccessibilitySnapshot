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

import SnapshotTesting
import UIKit

#if SWIFT_PACKAGE
import AccessibilitySnapshotCore
import AccessibilitySnapshotCore_ObjC
#endif

extension Snapshotting where Value == UIView, Format == UIImage {

    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    ///
    /// - Important: Using a `precision` less than 1 may result in allowing regressions through.
    ///
    /// - parameter showActivationPoints: When to show indicators for elements' accessibility activation points.
    /// Defaults to showing activation points only when they are different than the default activation point for that
    /// element.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    /// - parameter markerColors: The array of colors which will be chosen from when creating the overlays
    /// - parameter precision: The portion of pixels that must match for the image to be consider "unchanged". Value
    /// must be in the range `[0,1]`, where `0` means no pixels must match and `1` means all pixels must match.
    public static func impreciseAccessibilityImage(
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        markerColors: [UIColor] = [],
        precision: Float
    ) -> Snapshotting {
        guard isRunningInHostApplication else {
            fatalError("Accessibility snapshot tests cannot be run in a test target without a host application")
        }

        return Snapshotting<UIView, UIImage>
            .image(drawHierarchyInKeyWindow: drawHierarchyInKeyWindow, precision: precision)
            .pullback { view in
                let containerView = AccessibilitySnapshotView(
                    containedView: view,
                    viewRenderingMode: drawHierarchyInKeyWindow ? .drawHierarchyInRect : .renderLayerInContext,
                    markerColors: markerColors,
                    activationPointDisplayMode: activationPointDisplayMode
                )

                let window = UIWindow(frame: UIScreen.main.bounds)
                window.makeKeyAndVisible()
                containerView.center = window.center
                window.addSubview(containerView)

                do {
                    try containerView.parseAccessibility(useMonochromeSnapshot: useMonochromeSnapshot)
                } catch AccessibilitySnapshotView.Error.containedViewExceedsMaximumSize {
                    fatalError(
                        """
                        View is too large to render monochrome snapshot. Try setting useMonochromeSnapshot to false or \
                        use a different iOS version. In particular, this is known to fail on iOS 13, but was fixed in \
                        iOS 14.
                        """
                    )
                } catch AccessibilitySnapshotView.Error.containedViewHasUnsupportedTransform {
                    fatalError(
                        """
                        View has an unsupported transform for the specified snapshot parameters. Try using an identity \
                        transform or changing the view rendering mode to render the layer in the graphics context.
                        """
                    )
                } catch {
                    fatalError("Failed to render snapshot image")
                }

                containerView.sizeToFit()

                return containerView
            }
    }

    /// Snapshots the current view simulating the way it will appear with Smart Invert Colors enabled.
    public static func impreciseImageWithSmartInvert(precision: Float) -> Snapshotting {
       func postNotification() {
            NotificationCenter.default.post(
                name: UIAccessibility.invertColorsStatusDidChangeNotification,
                object: nil,
                userInfo: nil
            )
        }

        return Snapshotting<UIImage, UIImage>.image.pullback { view in
            let requiresWindow = (view.window == nil && !(view is UIWindow))

            if requiresWindow {
                let window = UIApplication.shared.firstKeyWindow ?? UIWindow(frame: UIScreen.main.bounds)
                window.addSubview(view)
            }

            view.layoutIfNeeded()

            let statusUtility = UIAccessibilityStatusUtility()
            statusUtility.mockInvertColorsStatus()
            postNotification()

            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            let image = renderer.image { context in
                view.drawHierarchyWithInvertedColors(in: view.bounds, using: context)
            }

            statusUtility.unmockStatuses()
            postNotification()

            if requiresWindow {
                view.removeFromSuperview()
            }

            return image
        }
    }

}

extension Snapshotting where Value == UIViewController, Format == UIImage {

    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    ///
    /// - parameter showActivationPoints: When to show indicators for elements' accessibility activation points.
    /// Defaults to showing activation points only when they are different than the default activation point for that
    /// element.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    /// - parameter markerColors: The array of colors which will be chosen from when creating the overlays
    public static func impreciseAccessibilityImage(
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        markerColors: [UIColor] = [],
        precision: Float
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .impreciseAccessibilityImage(
                showActivationPoints: activationPointDisplayMode,
                useMonochromeSnapshot: useMonochromeSnapshot,
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                markerColors: markerColors,
                precision: precision
            )
            .pullback { viewController in
                viewController.view
            }
    }

    /// Snapshots the current view simulating the way it will appear with Smart Invert Colors enabled.
    public static func impreciseImageWithSmartInvert(precision: Float) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .impreciseImageWithSmartInvert(precision: precision)
            .pullback { viewController in
                viewController.view
            }
    }

}

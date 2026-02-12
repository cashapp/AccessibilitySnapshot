import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import AccessibilitySnapshotParser_ObjC
import SnapshotTesting
import UIKit

public extension Snapshotting where Value == UIView, Format == UIImage {
    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    static var accessibilityImage: Snapshotting {
        return .accessibilityImage()
    }

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
    /// - parameter markerColors: The array of colors which will be chosen from when creating the overlays.
    /// - parameter showUserInputLabels: Controls when to show elements' accessibility user input labels (used by Voice
    /// Control).
    /// - parameter shouldRunInHostApplication: Controls whether a host application is required to run the test or not.
    /// - parameter precision: The percentage of pixels that must match. A value of `1` means all pixels must match,
    /// while a value of `0.95` means that 95% of pixels must match.
    /// - parameter perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match.
    /// `1` means the pixel must match exactly, while `0.98` means the pixel must be within 2% of the source pixel.
    static func accessibilityImage(
        showActivationPoints activationPointDisplayMode: AccessibilityContentDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        markerColors: [UIColor] = [],
        showUserInputLabels: Bool = true,
        shouldRunInHostApplication: Bool = true,
        precision: Float = 1,
        perceptualPrecision: Float = 1
    ) -> Snapshotting {
        guard !shouldRunInHostApplication || isRunningInHostApplication else {
            fatalError("Accessibility snapshot tests cannot be run in a test target without a host application")
        }

        return Snapshotting<UIView, UIImage>
            .image(drawHierarchyInKeyWindow: drawHierarchyInKeyWindow, precision: precision, perceptualPrecision: perceptualPrecision)
            .pullback { view in

                let configuration = AccessibilitySnapshotConfiguration(
                    viewRenderingMode: drawHierarchyInKeyWindow ? .drawHierarchyInRect : .renderLayerInContext,
                    colorRenderingMode: useMonochromeSnapshot ? .monochrome : .fullColor,
                    overlayColors: markerColors,
                    activationPointDisplay: activationPointDisplayMode,
                    includesInputLabels: showUserInputLabels ? .whenOverridden : .never
                )

                let containerView = AccessibilitySnapshotView(containedView: view, snapshotConfiguration: configuration)

                let window = UIWindow(frame: UIScreen.main.bounds)
                window.makeKeyAndVisible()
                containerView.center = window.center
                window.addSubview(containerView)

                do {
                    try containerView.parseAccessibility()
                } catch ImageRenderingError.containedViewExceedsMaximumSize {
                    fatalError(
                        """
                        View is too large to render monochrome snapshot. Try setting useMonochromeSnapshot to false or \
                        use a different iOS version. In particular, this is known to fail on iOS 13, but was fixed in \
                        iOS 14.
                        """
                    )
                } catch ImageRenderingError.containedViewHasUnsupportedTransform {
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
    static var imageWithSmartInvert: Snapshotting {
        return .imageWithSmartInvert()
    }

    /// Snapshots the current view simulating the way it will appear with Smart Invert Colors enabled.
    ///
    /// - parameter precision: The percentage of pixels that must match. A value of `1` means all pixels must match,
    /// while a value of `0.95` means that 95% of pixels must match.
    /// - parameter perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match.
    /// `1` means the pixel must match exactly, while `0.98` means the pixel must be within 2% of the source pixel.
    static func imageWithSmartInvert(
        precision: Float = 1,
        perceptualPrecision: Float = 1
    ) -> Snapshotting {
        func postNotification() {
            NotificationCenter.default.post(
                name: UIAccessibility.invertColorsStatusDidChangeNotification,
                object: nil,
                userInfo: nil
            )
        }

        return Snapshotting<UIImage, UIImage>.image(precision: precision, perceptualPrecision: perceptualPrecision).pullback { view in
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

    /// Snapshots the view with hit target regions highlighted.
    ///
    /// The hit target regions are highlighted using the following rules:
    ///
    /// * Regions that hit test to the base view will not be highlighted.
    /// * Regions that hit test to `nil` will be darkened.
    /// * Regions that hit test to another view will be highlighted using one of the specified `colors`.
    ///
    /// By default this snapshot is very slow (on the order of 50 seconds for a full screen snapshot) since it hit tests
    /// every pixel in the view to achieve a perfectly accurate result. As a performance optimization, you can trade off
    /// greatly increased performance for the possibility of missing very thin views by defining the maximum width and
    /// height of a region you are okay with missing (`maxPermissibleMissedRegion{Width,Height}`). In particular, this
    /// might miss hit regions of the specified width/height or less **which have the same hit target both above and
    /// below the region**. Note these are independent controls - a region could be missed if it falls beneath either of
    /// these thresholds, not both. Setting the either value alone to 1 pt improves the run time by almost (1 / scale
    /// factor), i.e. a 65% improvement for a 3x scale device, and setting both to 1 pt improves the run time by an
    /// additional (1 / scale factor), i.e. an ~88% improvement for a 3x scale device, so this trade-off is often worth
    /// it. Increasing the value from there will continue to decrease the run time, but you quickly get diminishing
    /// returns, so you likely won't ever want to go above 2-4 pt and should stick to 0 or 1 pt unless you have a large
    /// number of snapshots.
    ///
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the view should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    /// - parameter colors: An array of colors to use for the highlighted regions. These colors will be used in order,
    /// repeating through the array as necessary and avoiding adjacent regions using the same color when possible.
    /// - parameter maxPermissibleMissedRegionWidth: The maximum width for which it is permissible to "miss" a view.
    /// Value must be a positive integer.
    /// - parameter maxPermissibleMissedRegionHeight: The maximum height for which it is permissible to "miss" a view.
    /// Value must be a positive integer.
    /// - parameter file: The file in which errors should be attributed.
    /// - parameter line: The line in which errors should be attributed.
    /// - parameter precision: The percentage of pixels that must match. A value of `1` means all pixels must match,
    /// while a value of `0.95` means that 95% of pixels must match.
    /// - parameter perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match.
    /// `1` means the pixel must match exactly, while `0.98` means the pixel must be within 2% of the source pixel.
    static func imageWithHitTargets(
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        colors: [UIColor] = MarkerColors.defaultColors,
        maxPermissibleMissedRegionWidth: CGFloat = 0,
        maxPermissibleMissedRegionHeight: CGFloat = 0,
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .image(drawHierarchyInKeyWindow: drawHierarchyInKeyWindow, precision: precision, perceptualPrecision: perceptualPrecision)
            .pullback { view in
                do {
                    return try HitTargetSnapshotView(
                        baseView: view,
                        useMonochromeSnapshot: useMonochromeSnapshot,
                        viewRenderingMode: drawHierarchyInKeyWindow ? .drawHierarchyInRect : .renderLayerInContext,
                        colors: colors,
                        maxPermissibleMissedRegionWidth: maxPermissibleMissedRegionWidth,
                        maxPermissibleMissedRegionHeight: maxPermissibleMissedRegionHeight
                    )
                } catch ImageRenderingError.containedViewExceedsMaximumSize {
                    fatalError(
                        """
                        View is too large to render monochrome snapshot. Try setting useMonochromeSnapshot to false or \
                        use a different iOS version. In particular, this is known to fail on iOS 13, but was fixed in \
                        iOS 14.
                        """,
                        file: file,
                        line: line
                    )
                } catch ImageRenderingError.containedViewHasUnsupportedTransform {
                    fatalError(
                        """
                        View has an unsupported transform for the specified snapshot parameters. Try using an identity \
                        transform or changing the view rendering mode to render the layer in the graphics context.
                        """,
                        file: file,
                        line: line
                    )
                } catch {
                    fatalError("Failed to render snapshot image", file: file, line: line)
                }
            }
    }

    // MARK: - Internal Properties

    internal static var isRunningInHostApplication: Bool {
        // The tests must be run in a host application in order for the accessibility properties to be populated
        // correctly. The `UIApplication.shared` singleton is non-optional, but will be uninitialized when the tests are
        // running outside of a host application, so we can use this check to determine whether we have a test host.
        let hostApplication: UIApplication? = UIApplication.shared
        return hostApplication != nil
    }
}

public extension Snapshotting where Value == UIViewController, Format == UIImage {
    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    static var accessibilityImage: Snapshotting {
        return .accessibilityImage()
    }

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
    /// - parameter markerColors: The array of colors which will be chosen from when creating the overlays.
    /// - parameter showUserInputLabels: Controls when to show elements' accessibility user input labels (used by Voice
    /// Control).
    /// - parameter precision: The percentage of pixels that must match. A value of `1` means all pixels must match,
    /// while a value of `0.95` means that 95% of pixels must match.
    /// - parameter perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match.
    /// `1` means the pixel must match exactly, while `0.98` means the pixel must be within 2% of the source pixel.
    static func accessibilityImage(
        showActivationPoints activationPointDisplayMode: AccessibilityContentDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        markerColors: [UIColor] = [],
        showUserInputLabels: Bool = true,
        shouldRunInHostApplication: Bool = true,
        precision: Float = 1,
        perceptualPrecision: Float = 1
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .accessibilityImage(
                showActivationPoints: activationPointDisplayMode,
                useMonochromeSnapshot: useMonochromeSnapshot,
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                markerColors: markerColors,
                showUserInputLabels: showUserInputLabels,
                shouldRunInHostApplication: shouldRunInHostApplication,
                precision: precision,
                perceptualPrecision: perceptualPrecision
            )
            .pullback { viewController in
                viewController.view
            }
    }

    /// Snapshots the current view simulating the way it will appear with Smart Invert Colors enabled.
    static var imageWithSmartInvert: Snapshotting {
        return .imageWithSmartInvert()
    }

    /// Snapshots the current view simulating the way it will appear with Smart Invert Colors enabled.
    ///
    /// - parameter precision: The percentage of pixels that must match. A value of `1` means all pixels must match,
    /// while a value of `0.95` means that 95% of pixels must match.
    /// - parameter perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match.
    /// `1` means the pixel must match exactly, while `0.98` means the pixel must be within 2% of the source pixel.
    static func imageWithSmartInvert(
        precision: Float = 1,
        perceptualPrecision: Float = 1
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .imageWithSmartInvert(precision: precision, perceptualPrecision: perceptualPrecision)
            .pullback { viewController in
                viewController.view
            }
    }

    /// Snapshots the view controller with hit target regions highlighted.
    ///
    /// The hit target regions are highlighted using the following rules:
    ///
    /// * Regions that hit test to the base view (the view controller's `view`) will not be highlighted.
    /// * Regions that hit test to `nil` will be darkened.
    /// * Regions that hit test to another view will be highlighted using one of the specified `colors`.
    ///
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the view should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    /// - parameter colors: An array of colors to use for the highlighted regions. These colors will be used in order,
    /// repeating through the array as necessary and avoiding adjacent regions using the same color when possible.
    /// - parameter file: The file in which errors should be attributed.
    /// - parameter line: The line in which errors should be attributed.
    /// - parameter precision: The percentage of pixels that must match. A value of `1` means all pixels must match,
    /// while a value of `0.95` means that 95% of pixels must match.
    /// - parameter perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match.
    /// `1` means the pixel must match exactly, while `0.98` means the pixel must be within 2% of the source pixel.
    static func imageWithHitTargets(
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        colors: [UIColor] = MarkerColors.defaultColors,
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .imageWithHitTargets(
                useMonochromeSnapshot: useMonochromeSnapshot,
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                colors: colors,
                precision: precision,
                perceptualPrecision: perceptualPrecision,
                file: file,
                line: line
            )
            .pullback { viewController in
                viewController.view
            }
    }
}

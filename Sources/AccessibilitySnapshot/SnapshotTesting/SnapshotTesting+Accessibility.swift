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
    public static var accessibilityImage: Snapshotting {
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
    /// - parameter markerColors: The array of colors which will be chosen from when creating the overlays
    public static func accessibilityImage(
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        markerColors: [UIColor] = []
    ) -> Snapshotting {
        // For now this calls through to the imprecise variant, but should eventually use an alternate comparison
        // algorithm that... TODO
        return .impreciseAccessibilityImage(
            showActivationPoints: activationPointDisplayMode,
            useMonochromeSnapshot: useMonochromeSnapshot,
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
            markerColors: markerColors,
            precision: 1
        )
    }

    /// Snapshots the current view using the specified content size category to test Dynamic Type.
    ///
    /// This method has been marked internal since it is still under development. Once it has been completed, it should
    /// be made `public`.
    ///
    /// - parameter contentSizeCategory: The content size category to use in the snapshot
    static func image(
        at contentSizeCategory: UIContentSizeCategory
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>.image(
            traits: .init(preferredContentSizeCategory: contentSizeCategory)
        )
    }

    /// Snapshots the current view simulating the way it will appear with Smart Invert Colors enabled.
    public static var imageWithSmartInvert: Snapshotting {
        return .impreciseImageWithSmartInvert(precision: 1)
    }

    // MARK: - Internal Properties

    internal static var isRunningInHostApplication: Bool {
        // The tests must be run in a host application in order for the accessibility properties to be populated
        // correctly. The `UIApplication.shared` singleton is non-optional, but will be uninitialized when the tests are
        // running outside of a host application, so we can use this check to determine whether we have a test host.
        let hostApplication: UIApplication? = UIApplication.shared
        return (hostApplication != nil)
    }

}

extension Snapshotting where Value == UIViewController, Format == UIImage {

    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    public static var accessibilityImage: Snapshotting {
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
    /// - parameter markerColors: The array of colors which will be chosen from when creating the overlays
    public static func accessibilityImage(
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        markerColors: [UIColor] = []
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .accessibilityImage(
                showActivationPoints: activationPointDisplayMode,
                useMonochromeSnapshot: useMonochromeSnapshot,
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                markerColors: markerColors
            )
            .pullback { viewController in
                viewController.view
            }
    }

    /// Snapshots the current view using the specified content size category to test Dynamic Type.
    ///
    /// This method has been marked internal since it is still under development. Once it has been completed, it should
    /// be made `public`.
    ///
    /// - parameter contentSizeCategory: The content size category to use in the snapshot
    static func image(
        at contentSizeCategory: UIContentSizeCategory
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .image(
                traits: .init(preferredContentSizeCategory: contentSizeCategory)
            )
            .pullback { viewController in
                viewController.view
            }
    }

    /// Snapshots the current view simulating the way it will appear with Smart Invert Colors enabled.
    public static var imageWithSmartInvert: Snapshotting {
        return Snapshotting<UIView, UIImage>.imageWithSmartInvert.pullback { viewController in
            viewController.view
        }
    }

}

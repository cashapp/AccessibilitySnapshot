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
import SwiftUI
import UIKit

#if SWIFT_PACKAGE || BAZEL_PACKAGE
import AccessibilitySnapshotCore
import AccessibilitySnapshotCore_ObjC
#endif

extension Snapshotting where Value: SwiftUI.View, Format == UIImage {

    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    public static var accessibilityImage: Snapshotting {
        return .accessibilityImage()
    }

    /// Snapshots the current view with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    ///
    /// - parameter size: The size of the snapshotted view. Note this size does not include the legend. Pass `nil` to
    /// use the view's size that fits.
    /// - parameter showActivationPoints: When to show indicators for elements' accessibility activation points.
    /// Defaults to showing activation points only when they are different than the default activation point for that
    /// element.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the view should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter drawHierarchyInKeyWindow: Whether or not to draw the view hierachy in the key window, rather than
    /// rendering the view's layer. This enables the rendering of `UIAppearance` and `UIVisualEffect`s.
    /// - parameter markerColors: The array of colors which will be chosen from when creating the overlays.
    /// - parameter showUserInputLabels: Controls when to show elements' accessibility user input labels (used by Voice
    /// Control).
    public static func accessibilityImage(
        size: CGSize? = nil,
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        drawHierarchyInKeyWindow: Bool = false,
        markerColors: [UIColor] = [],
        showUserInputLabels: Bool = true
    ) -> Snapshotting {
        return Snapshotting<UIViewController, UIImage>
            .accessibilityImage(
                showActivationPoints: activationPointDisplayMode,
                useMonochromeSnapshot: useMonochromeSnapshot,
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                markerColors: markerColors,
                showUserInputLabels: showUserInputLabels
            )
            .pullback { (view: Value) in
                let hostingController = UIHostingController(rootView: view)
                hostingController.view.bounds.size = size ?? hostingController.sizeThatFits(in: .zero)
                return hostingController
            }
    }

    /// Snapshots the view simulating the way it will appear with Smart Invert Colors enabled.
    public static var imageWithSmartInvert: Snapshotting {
        return Snapshotting<UIViewController, UIImage>
            .imageWithSmartInvert
            .pullback { (view: Value) in
                return UIHostingController(rootView: view)
            }
    }

}

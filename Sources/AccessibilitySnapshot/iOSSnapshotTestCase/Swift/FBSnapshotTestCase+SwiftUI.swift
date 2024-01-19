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

import SwiftUI

#if SWIFT_PACKAGE || BAZEL_PACKAGE
import AccessibilitySnapshotCore
import iOSSnapshotTestCase
#else
import FBSnapshotTestCase
#endif

extension FBSnapshotTestCase {

    /// Snapshots the `view` with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    ///
    /// When `recordMode` is true, records a snapshot of the view. When `recordMode` is false, performs a comparison
    /// with the existing snapshot.
    ///
    /// - parameter view: The view that will be snapshotted.
    /// - parameter size: The size of the `view`. Note this size does not include the legend. Pass `nil` to use the
    /// view's size that fits.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter showActivationPoints: When to show indicators for elements' accessibility activation points.
    /// Defaults to showing activation points only when they are different than the default activation point for that
    /// element.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views. Defaults to `true`.
    /// - parameter markerColors: An array of colors to use for the highlighted regions. These colors will be used in
    /// order, repeating through the array as necessary.
    /// - parameter suffixes: An `NSOrderedSet` object containing strings that are appended to the reference images
    /// directory. Defaults to `FBSnapshotTestCaseDefaultSuffixes()`.
    /// - parameter showUserInputLabels: Controls when to show elements' accessibility user input labels (used by Voice
    /// Control).
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    public func SnapshotVerifyAccessibility<View: SwiftUI.View>(
        _ view: View,
        size: CGSize? = nil,
        identifier: String = "",
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        markerColors: [UIColor] = [],
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        showUserInputLabels: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.bounds.size = size ?? hostingController.sizeThatFits(in: .zero)

        SnapshotVerifyAccessibility(
            hostingController.view,
            identifier: identifier,
            showActivationPoints: activationPointDisplayMode,
            useMonochromeSnapshot: useMonochromeSnapshot,
            markerColors: markerColors,
            suffixes: suffixes,
            showUserInputLabels: showUserInputLabels,
            file: file,
            line: line
        )
    }

    /// Snapshots the `view` simulating the way it will appear with Smart Invert Colors enabled.
    ///
    /// When `recordMode` is true, records a snapshot of the view. When `recordMode` is false, performs a comparison
    /// with the existing snapshot.
    ///
    /// - parameter view: The view that will be snapshotted.
    /// - parameter size: The size of the `view`. Note this size does not include the legend. Pass `nil` to use the
    /// view's size that fits.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter suffixes: An `NSOrderedSet` object containing strings that are appended to the reference images
    /// directory. Defaults to `FBSnapshotTestCaseDefaultSuffixes()`.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    public func SnapshotVerifyWithInvertedColors<View: SwiftUI.View>(
        _ view: View,
        size: CGSize? = nil,
        identifier: String = "",
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.bounds.size = size ?? hostingController.sizeThatFits(in: .zero)

        SnapshotVerifyWithInvertedColors(
            hostingController.view,
            identifier: identifier,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

}

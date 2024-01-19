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

import XCTest

#if SWIFT_PACKAGE || BAZEL_PACKAGE
import AccessibilitySnapshotCore
import AccessibilitySnapshotCore_ObjC
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
    /// - Note: This method will modify the view hierarchy in order to snapshot the view. It will attempt to restore the
    /// hierarchy to its original state as much as possible, but is not guaranteed to be without side effects (for
    /// example if something observes changes in the view hierarchy).
    ///
    /// - parameter view: The view that will be snapshotted.
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
    /// - parameter suffixes: NSOrderedSet object containing strings that are appended to the reference images
    /// directory. Defaults to `FBSnapshotTestCaseDefaultSuffixes()`.
    /// - parameter showUserInputLabels: Controls when to show elements' accessibility user input labels (used by Voice
    /// Control).
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    public func SnapshotVerifyAccessibility(
        _ view: UIView,
        identifier: String = "",
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        markerColors: [UIColor] = [],
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        showUserInputLabels: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard isRunningInHostApplication else {
            XCTFail(ErrorMessageFactory.errorMessageForMissingHostApplication, file: file, line: line)
            return
        }

        let containerView = AccessibilitySnapshotView(
            containedView: view,
            viewRenderingMode: (usesDrawViewHierarchyInRect ? .drawHierarchyInRect : .renderLayerInContext),
            markerColors: markerColors,
            activationPointDisplayMode: activationPointDisplayMode,
            showUserInputLabels: showUserInputLabels
        )

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        containerView.center = window.center
        window.addSubview(containerView)

        do {
            try containerView.parseAccessibility(useMonochromeSnapshot: useMonochromeSnapshot)
        } catch {
            XCTFail(ErrorMessageFactory.errorMessageForAccessibilityParsingError(error), file: file, line: line)
            return
        }
        containerView.sizeToFit()

        FBSnapshotVerifyView(containerView, identifier: identifier, suffixes: suffixes, file: file, line: line)
    }

    /// Snapshots the `view` simulating the way it will appear with Smart Invert Colors enabled.
    ///
    /// When `recordMode` is true, records a snapshot of the view. When `recordMode` is false, performs a comparison
    /// with the existing snapshot.
    ///
    /// - parameter view: The view that will be snapshotted.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter suffixes: NSOrderedSet object containing strings that are appended to the reference images
    /// directory. Defaults to `FBSnapshotTestCaseDefaultSuffixes()`.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    public func SnapshotVerifyWithInvertedColors(
        _ view: UIView,
        identifier: String = "",
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        func postNotification() {
            NotificationCenter.default.post(
                name: UIAccessibility.invertColorsStatusDidChangeNotification,
                object: nil,
                userInfo: nil
            )
        }

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

        let imageView = UIImageView(image: image)
        FBSnapshotVerifyView(imageView, identifier: identifier, suffixes: suffixes, file: file, line: line)

        statusUtility.unmockStatuses()
        postNotification()

        if requiresWindow {
            view.removeFromSuperview()
        }
    }

    /// Snapshots the `view` with hit target regions highlighted.
    ///
    /// The hit target regions are highlighted using the following rules:
    ///
    /// * Regions that hit test to the base view (`view`) will not be highlighted.
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
    /// - parameter view: The view to be snapshotted.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple\
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views.
    /// - parameter colors: An array of colors to use for the highlighted regions. These colors will be used in order,
    /// repeating through the array as necessary and avoiding adjacent regions using the same color when possible.
    /// - parameter maxPermissibleMissedRegionWidth: The maximum width for which it is permissible to "miss" a view.
    /// Value must be a positive integer.
    /// - parameter maxPermissibleMissedRegionHeight: The maximum height for which it is permissible to "miss" a view.
    /// Value must be a positive integer.
    /// - parameter suffixes: NSOrderedSet object containing strings that are appended to the reference images
    /// directory. Defaults to `FBSnapshotTestCaseDefaultSuffixes()`.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    public func SnapshotVerifyWithHitTargets(
        _ view: UIView,
        identifier: String = "",
        useMonochromeSnapshot: Bool = true,
        colors: [UIColor] = AccessibilitySnapshotView.defaultMarkerColors,
        maxPermissibleMissedRegionWidth: CGFloat = 0,
        maxPermissibleMissedRegionHeight: CGFloat = 0,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        SnapshotImpreciseVerifyWithHitTargets(
            view,
            identifier: identifier,
            useMonochromeSnapshot: useMonochromeSnapshot,
            colors: colors,
            maxPermissibleMissedRegionWidth: maxPermissibleMissedRegionWidth,
            maxPermissibleMissedRegionHeight: maxPermissibleMissedRegionHeight,
            suffixes: suffixes,
            perPixelTolerance: 0,
            overallTolerance: 0,
            file: file,
            line: line
        )
    }

    // MARK: - Internal Properties

    var isRunningInHostApplication: Bool {
        // The tests must be run in a host application in order for the accessibility properties to be populated
        // correctly. The `UIApplication.shared` singleton is non-optional, but will be uninitialized when the tests are
        // running outside of a host application, so we can use this check to determine whether we have a test host.
        let hostApplication: UIApplication? = UIApplication.shared
        return (hostApplication != nil)
    }

}

//
//  Copyright 2019 Square Inc.
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

#if SWIFT_PACKAGE
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
    /// - parameter caTransactionCongfiguration: The `CATransaction` configuration to utilize while laying out the
    /// content view. When `nil`, no custom `CATransaction` will be utilized during layout.
    /// - parameter suffixes: NSOrderedSet object containing strings that are appended to the reference images
    /// directory. Defaults to `FBSnapshotTestCaseDefaultSuffixes()`.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    public func SnapshotVerifyAccessibility(
        _ view: UIView,
        identifier: String = "",
        showActivationPoints activationPointDisplayMode: ActivationPointDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        markerColors: [UIColor] = [],
        caTransactionCongfiguration: CATransactionCongfiguration? = nil,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
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
            caTransactionCongfiguration: caTransactionCongfiguration
        )

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        containerView.center = window.center
        // Adding the containedView as a subview can trigger didMoveToWindow() and/or didMoveToSuperview() which view
        // subclasses may utilize to begin CALayer animations.
        // Use the CATransactionConfiguration to perform this operation to assist with those usecases.
        CATransaction.perform(configuration: caTransactionCongfiguration) {
            window.addSubview(containerView)
        }

        do {
            try containerView.parseAccessibility(useMonochromeSnapshot: useMonochromeSnapshot)
        } catch {
            XCTFail(ErrorMessageFactory.errorMessageForAccessibilityParsingError(error), file: file, line: line)
            return
        }
        containerView.sizeToFit()

        FBSnapshotVerifyView(containerView, identifier: identifier, suffixes: suffixes, file: file, line: line)
    }

    /// Snapshots the `view` using the specified content size category to test Dynamic Type.
    ///
    /// When `recordMode` is true, records a snapshot of the view. When `recordMode` is false, performs a comparison with the
    /// existing snapshot.
    ///
    /// In preparation for beta release, this method has been marked internal since it is still under development. Once
    /// it has been completed, it should be made `public`.
    ///
    /// - parameter view: The view that will be snapshotted.
    /// - parameter contentSizeCategory: The content size category to use in the snapshot.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple snapshot tests
    /// in a given test method. Defaults to no identifier.
    /// - parameter suffixes: NSOrderedSet object containing strings that are appended to the reference images directory.
    /// Defaults to `FBSnapshotTestCaseDefaultSuffixes()`.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    func SnapshotVerify(
        _ view: UIView,
        at contentSizeCategory: UIContentSizeCategory,
        identifier: String = "",
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        func postNotification() {
            NotificationCenter.default.post(
                name: UIContentSizeCategory.didChangeNotification,
                object: UIScreen.main,
                userInfo: [
                    UIContentSizeCategory.newValueUserInfoKey: UIApplication.shared.preferredContentSizeCategory,
                    "UIContentSizeCategoryTextLegibilityEnabledKey": false,
                ]
            )
        }

        let originalTraitCollection = view.traitCollection
        UIView.setPreferredContentSizeCategoryOverride(contentSizeCategory)
        view.processChange(from: originalTraitCollection)
        postNotification()

        // TODO: This doesn't quite match what actually happens when the Dynamic Type setting changes. There are a few different ways
        // to change Dynamic Type (via the Accessibility Inspector in a simulator, exiting the app and changing the size in
        // Settings.app, or via a control in Control Center on a device) and they each hit a slightly different path when it comes to
        // resizing views. We should probably try to match the Control Center path since that is the most dynamic way actual users
        // will be able to change the text size in production.
        view.setNeedsLayout()

        FBSnapshotVerifyView(view, identifier: identifier, suffixes: suffixes, file: file, line: line)

        // Restore the original content size category.
        let overriddenTraitCollection = view.traitCollection
        UIView.setPreferredContentSizeCategoryOverride(nil)
        view.processChange(from: overriddenTraitCollection)
        postNotification()
        view.setNeedsLayout()
    }

    /// Snapshots the `view` simulating the way it will appear with Smart Invert Colors enabled.
    ///
    /// When `recordMode` is true, records a snapshot of the view. When `recordMode` is false, performs a comparison with the
    /// existing snapshot.
    ///
    /// - parameter view: The view that will be snapshotted.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple snapshot tests
    /// in a given test method. Defaults to no identifier.
    /// - parameter suffixes: NSOrderedSet object containing strings that are appended to the reference images directory.
    /// Defaults to `FBSnapshotTestCaseDefaultSuffixes()`.
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
            let window = UIApplication.shared.keyWindow ?? UIWindow(frame: UIScreen.main.bounds)
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
        FBSnapshotVerifyView(imageView, suffixes: suffixes, file: file, line: line)

        statusUtility.unmockStatuses()
        postNotification()

        if requiresWindow {
            view.removeFromSuperview()
        }
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

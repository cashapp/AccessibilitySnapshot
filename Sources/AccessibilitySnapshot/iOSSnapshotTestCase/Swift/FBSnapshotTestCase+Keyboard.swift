//
//  Copyright 2024 Block Inc.
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

import AccessibilitySnapshotCore
import iOSSnapshotTestCase
import SwiftUI
import UIKit

public extension FBSnapshotTestCase {
    // MARK: - UIView Snapshots

    /// Snapshots the given view with a legend showing keyboard accessibility information.
    ///
    /// This variant parses shortcuts from the view's responder chain, without category grouping.
    ///
    /// - parameter view: The view to snapshot.
    /// - parameter identifier: An optional identifier included in the snapshot name.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot should be monochrome. Defaults to `true`.
    /// - parameter suffixes: NSOrderedSet of strings appended to the reference images directory.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    func SnapshotVerifyKeyboardAccessibility(
        _ view: UIView,
        identifier: String = "",
        useMonochromeSnapshot: Bool = true,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        snapshotVerifyKeyboardAccessibilityImpl(
            view: view,
            menu: nil,
            identifier: identifier,
            useMonochromeSnapshot: useMonochromeSnapshot,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

    /// Snapshots the given view with a legend showing keyboard shortcuts from a UIMenu.
    ///
    /// This variant uses the provided UIMenu to extract shortcuts with category grouping.
    ///
    /// - parameter view: The view to snapshot.
    /// - parameter menu: The UIMenu containing keyboard shortcuts organized by category.
    /// - parameter identifier: An optional identifier included in the snapshot name.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot should be monochrome. Defaults to `true`.
    /// - parameter suffixes: NSOrderedSet of strings appended to the reference images directory.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    func SnapshotVerifyKeyboardAccessibility(
        _ view: UIView,
        menu: UIMenu,
        identifier: String = "",
        useMonochromeSnapshot: Bool = true,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        snapshotVerifyKeyboardAccessibilityImpl(
            view: view,
            menu: menu,
            identifier: identifier,
            useMonochromeSnapshot: useMonochromeSnapshot,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

    // MARK: - UIViewController Snapshots

    /// Snapshots the given view controller's view with a legend showing keyboard accessibility information.
    ///
    /// This variant parses shortcuts from the view controller's responder chain, without category grouping.
    ///
    /// - parameter viewController: The view controller whose view to snapshot.
    /// - parameter identifier: An optional identifier included in the snapshot name.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot should be monochrome. Defaults to `true`.
    /// - parameter suffixes: NSOrderedSet of strings appended to the reference images directory.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    func SnapshotVerifyKeyboardAccessibility(
        _ viewController: UIViewController,
        identifier: String = "",
        useMonochromeSnapshot: Bool = true,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        SnapshotVerifyKeyboardAccessibility(
            viewController.view,
            identifier: identifier,
            useMonochromeSnapshot: useMonochromeSnapshot,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

    /// Snapshots the given view controller's view with a legend showing keyboard shortcuts from a UIMenu.
    ///
    /// This variant uses the provided UIMenu to extract shortcuts with category grouping.
    ///
    /// - parameter viewController: The view controller whose view to snapshot.
    /// - parameter menu: The UIMenu containing keyboard shortcuts organized by category.
    /// - parameter identifier: An optional identifier included in the snapshot name.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot should be monochrome. Defaults to `true`.
    /// - parameter suffixes: NSOrderedSet of strings appended to the reference images directory.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    func SnapshotVerifyKeyboardAccessibility(
        _ viewController: UIViewController,
        menu: UIMenu,
        identifier: String = "",
        useMonochromeSnapshot: Bool = true,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        SnapshotVerifyKeyboardAccessibility(
            viewController.view,
            menu: menu,
            identifier: identifier,
            useMonochromeSnapshot: useMonochromeSnapshot,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

    /// Snapshots the given view controller's view with a legend showing keyboard shortcuts.
    ///
    /// This variant uses a key path to extract the UIMenu from the view controller.
    ///
    /// - parameter viewController: The view controller whose view to snapshot.
    /// - parameter menuKeyPath: A key path to the UIMenu property on the view controller.
    /// - parameter identifier: An optional identifier included in the snapshot name.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot should be monochrome. Defaults to `true`.
    /// - parameter suffixes: NSOrderedSet of strings appended to the reference images directory.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    func SnapshotVerifyKeyboardAccessibility<ViewController: UIViewController>(
        _ viewController: ViewController,
        menuKeyPath: KeyPath<ViewController, UIMenu>,
        identifier: String = "",
        useMonochromeSnapshot: Bool = true,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        SnapshotVerifyKeyboardAccessibility(
            viewController.view,
            menu: viewController[keyPath: menuKeyPath],
            identifier: identifier,
            useMonochromeSnapshot: useMonochromeSnapshot,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

    // MARK: - SwiftUI Snapshots

    /// Snapshots the given SwiftUI view with a legend showing keyboard accessibility information.
    ///
    /// This variant parses shortcuts from the view's responder chain, without category grouping.
    ///
    /// - parameter view: The SwiftUI view to snapshot.
    /// - parameter identifier: An optional identifier included in the snapshot name.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot should be monochrome. Defaults to `true`.
    /// - parameter suffixes: NSOrderedSet of strings appended to the reference images directory.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    func SnapshotVerifyKeyboardAccessibility<Content: View>(
        _ view: Content,
        identifier: String = "",
        useMonochromeSnapshot: Bool = true,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        snapshotVerifyKeyboardAccessibilitySwiftUIImpl(
            view: view,
            menu: nil,
            identifier: identifier,
            useMonochromeSnapshot: useMonochromeSnapshot,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

    /// Snapshots the given SwiftUI view with a legend showing keyboard shortcuts from a UIMenu.
    ///
    /// This variant uses the provided UIMenu to extract shortcuts with category grouping.
    ///
    /// - parameter view: The SwiftUI view to snapshot.
    /// - parameter menu: The UIMenu containing keyboard shortcuts organized by category.
    /// - parameter identifier: An optional identifier included in the snapshot name.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot should be monochrome. Defaults to `true`.
    /// - parameter suffixes: NSOrderedSet of strings appended to the reference images directory.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    func SnapshotVerifyKeyboardAccessibility<Content: View>(
        _ view: Content,
        menu: UIMenu,
        identifier: String = "",
        useMonochromeSnapshot: Bool = true,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        snapshotVerifyKeyboardAccessibilitySwiftUIImpl(
            view: view,
            menu: menu,
            identifier: identifier,
            useMonochromeSnapshot: useMonochromeSnapshot,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

    // MARK: - Private Implementation

    private func snapshotVerifyKeyboardAccessibilityImpl(
        view: UIView,
        menu: UIMenu?,
        identifier: String,
        useMonochromeSnapshot: Bool,
        suffixes: NSOrderedSet,
        file: StaticString,
        line: UInt
    ) {
        let keyboardViewRenderingMode: KeyboardAccessibilitySnapshotView.ViewRenderingMode =
            viewRenderingMode == .drawHierarchyInRect ? .drawHierarchyInRect : .renderLayerInContext

        let containerView = KeyboardAccessibilitySnapshotView(
            containedView: view,
            viewRenderingMode: keyboardViewRenderingMode,
            useMonochromeSnapshot: useMonochromeSnapshot
        )

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        containerView.center = window.center
        window.addSubview(containerView)

        parseAndVerify(
            containerView: containerView,
            menu: menu,
            identifier: identifier,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

    private func snapshotVerifyKeyboardAccessibilitySwiftUIImpl<Content: View>(
        view: Content,
        menu: UIMenu?,
        identifier: String,
        useMonochromeSnapshot: Bool,
        suffixes: NSOrderedSet,
        file: StaticString,
        line: UInt
    ) {
        let hostingController = UIHostingController(rootView: view)
        let hostingView = hostingController.view!
        hostingView.bounds.size = hostingController.sizeThatFits(in: .zero)

        let containerView = KeyboardAccessibilitySnapshotView(
            containedView: hostingView,
            viewRenderingMode: .drawHierarchyInRect,
            useMonochromeSnapshot: useMonochromeSnapshot
        )

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        containerView.center = window.center
        window.addSubview(containerView)

        hostingView.setNeedsLayout()
        hostingView.layoutIfNeeded()

        parseAndVerify(
            containerView: containerView,
            menu: menu,
            identifier: identifier,
            suffixes: suffixes,
            file: file,
            line: line
        )
    }

    private func parseAndVerify(
        containerView: KeyboardAccessibilitySnapshotView,
        menu: UIMenu?,
        identifier: String,
        suffixes: NSOrderedSet,
        file: StaticString,
        line: UInt
    ) {
        do {
            if let menu = menu {
                try containerView.parseKeyboardShortcuts(from: menu)
            } else {
                try containerView.parseKeyboardShortcuts()
            }
        } catch {
            XCTFail("Failed to parse keyboard shortcuts: \(error)", file: file, line: line)
            return
        }

        containerView.sizeToFit()
        FBSnapshotVerifyView(containerView, identifier: identifier, suffixes: suffixes, file: file, line: line)
    }
}

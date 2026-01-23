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
@testable import AccessibilitySnapshotDemo
import FBSnapshotTestCase_Accessibility
import UIKit
import XCTest

final class KeyboardAccessibilityTests: SnapshotTestCase {
    // MARK: - UIKit Tests

    func testKeyboardShortcutsWithCategories() {
        let viewController = KeyboardShortcutsViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyKeyboardAccessibility(viewController, menuKeyPath: \.keyboardShortcutsMenu)
    }

    func testKeyboardShortcutsWithoutCategories() {
        let viewController = KeyboardShortcutsWithoutCategoriesViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyKeyboardAccessibility(viewController.view)
    }

    // MARK: - SwiftUI Tests

    @available(iOS 14.0, *)
    func testSwiftUIKeyboardShortcuts() {
        SnapshotVerifyKeyboardAccessibility(SwiftUIKeyboardShortcuts())
    }
}

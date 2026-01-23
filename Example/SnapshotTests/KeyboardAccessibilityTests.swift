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

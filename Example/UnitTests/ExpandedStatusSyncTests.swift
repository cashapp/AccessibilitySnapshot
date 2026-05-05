import ObjectiveC
import UIKit
import XCTest

// These tests reference the public iOS 18 `accessibilityExpandedStatus` property, which is only
// present in the iOS 18 SDK (Xcode 16+). The iOS 17 CI job uses Xcode 15, so compile the file out
// there — the tests are `@available(iOS 18.0, *)` and cannot run on the iOS 17 simulator anyway.
#if compiler(>=6.0)

    /// Guards the invariants that justify reading the private `_accessibilityExpandedStatus`
    /// selector instead of the public iOS 18 `accessibilityExpandedStatus` property:
    ///
    /// 1. The public setter always syncs to the private getter on stock UIKit views.
    /// 2. No private setter exists, so subclass override is the only way the two values
    ///    can diverge — exactly what `SwiftUI.AccessibilityNode` does.
    @available(iOS 18.0, *)
    final class ExpandedStatusSyncTests: XCTestCase {
        private let privateGetSel = NSSelectorFromString("_accessibilityExpandedStatus")
        private let privateSetSel = NSSelectorFromString("_setAccessibilityExpandedStatus:")

        private func readPrivate(_ obj: NSObject) -> Int {
            let imp = obj.method(for: privateGetSel)
            typealias Fn = @convention(c) (AnyObject, Selector) -> Int
            return unsafeBitCast(imp, to: Fn.self)(obj, privateGetSel)
        }

        func testPublicSetterSyncsToPrivateGetter() {
            let view = UIView()

            view.accessibilityExpandedStatus = .expanded
            XCTAssertEqual(readPrivate(view), 1)

            view.accessibilityExpandedStatus = .collapsed
            XCTAssertEqual(readPrivate(view), 2)

            view.accessibilityExpandedStatus = .unsupported
            XCTAssertEqual(readPrivate(view), 0)
        }

        func testNoPrivateSetterExists() {
            XCTAssertFalse(UIView().responds(to: privateSetSel))
            XCTAssertFalse(NSObject().responds(to: privateSetSel))
        }

        func testNSObjectMatchesUIViewBehavior() {
            let obj = NSObject()

            obj.accessibilityExpandedStatus = .expanded
            XCTAssertEqual(readPrivate(obj), 1)

            obj.accessibilityExpandedStatus = .collapsed
            XCTAssertEqual(readPrivate(obj), 2)

            obj.accessibilityExpandedStatus = .unsupported
            XCTAssertEqual(readPrivate(obj), 0)
        }

        func testSubclassOverrideIsTheOnlyDivergencePath() {
            class OverrideView: UIView {
                var forcedPrivate: Int = 0
                @objc func _accessibilityExpandedStatus() -> Int {
                    return forcedPrivate
                }
            }

            let view = OverrideView()
            view.accessibilityExpandedStatus = .expanded
            view.forcedPrivate = 2

            XCTAssertEqual(view.accessibilityExpandedStatus.rawValue, 1)
            XCTAssertEqual(readPrivate(view), 2)

            // The public setter cannot fix a subclass override — this is the SwiftUI scenario.
            view.accessibilityExpandedStatus = .unsupported
            XCTAssertEqual(readPrivate(view), 2)
        }
    }

#endif

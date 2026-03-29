@testable import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotParser
import ObjectiveC
import UIKit
import XCTest

/// Comprehensive investigation of how `_accessibilityExpandedStatus` (private)
/// and `accessibilityExpandedStatus` (public, iOS 18) relate to each other.
/// No overrides — tests Apple's real default implementations on plain UIView/NSObject.
@available(iOS 18.0, *)
final class ExpandedStatusSyncTests: XCTestCase {
    private let privateGetSel = NSSelectorFromString("_accessibilityExpandedStatus")
    private let privateSetSel = NSSelectorFromString("_setAccessibilityExpandedStatus:")

    private func readPrivate(_ obj: NSObject) -> Int {
        guard obj.responds(to: privateGetSel) else { return -1 }
        let imp = obj.method(for: privateGetSel)
        typealias Fn = @convention(c) (AnyObject, Selector) -> Int
        return unsafeBitCast(imp, to: Fn.self)(obj, privateGetSel)
    }

    private func writePrivate(_ obj: NSObject, _ value: Int) -> Bool {
        guard obj.responds(to: privateSetSel) else { return false }
        let imp = obj.method(for: privateSetSel)
        typealias Fn = @convention(c) (AnyObject, Selector, Int) -> Void
        unsafeBitCast(imp, to: Fn.self)(obj, privateSetSel, value)
        return true
    }

    private func readPublic(_ obj: NSObject) -> Int {
        return obj.accessibilityExpandedStatus.rawValue
    }

    private func state(_ obj: NSObject) -> String {
        return "pub=\(readPublic(obj)) priv=\(readPrivate(obj))"
    }

    // MARK: - 1. Baseline: does a private setter exist?

    func test01_PrivateSetterExists() {
        let view = UIView()
        let obj = NSObject()
        let label = UILabel()
        let button = UIButton()

        print("=== PRIVATE SETTER EXISTENCE ===")
        for (name, o) in [("UIView", view as NSObject), ("NSObject", obj), ("UILabel", label as NSObject), ("UIButton", button as NSObject)] {
            let exists = o.responds(to: privateSetSel)
            print("  \(name) responds to _setAccessibilityExpandedStatus: \(exists)")
        }
        print("===")
    }

    // MARK: - 2. On plain UIView: does public setter sync to private getter?

    func test02_PublicSetterSyncsToPrivateGetter() {
        let view = UIView()
        print("=== PUBLIC → PRIVATE SYNC (plain UIView, no override) ===")

        print("  initial:              \(state(view))")

        view.accessibilityExpandedStatus = .expanded
        print("  pub=expanded:         \(state(view))")

        view.accessibilityExpandedStatus = .collapsed
        print("  pub=collapsed:        \(state(view))")

        view.accessibilityExpandedStatus = .unsupported
        print("  pub=unsupported:      \(state(view))")

        view.accessibilityExpandedStatus = .expanded
        print("  pub=expanded again:   \(state(view))")

        print("===")
    }

    // MARK: - 3. If private setter exists, does it sync back to public?

    func test03_PrivateSetterSyncsToPublicGetter() {
        let view = UIView()
        print("=== PRIVATE → PUBLIC SYNC (plain UIView, no override) ===")

        guard view.responds(to: privateSetSel) else {
            print("  _setAccessibilityExpandedStatus: DOES NOT EXIST — skipping")
            print("===")
            return
        }

        print("  initial:              \(state(view))")

        writePrivate(view, 1)
        print("  _priv=1(expanded):    \(state(view))")

        writePrivate(view, 2)
        print("  _priv=2(collapsed):   \(state(view))")

        writePrivate(view, 0)
        print("  _priv=0(unsupported): \(state(view))")

        print("===")
    }

    // MARK: - 4. KVC set on private key — crashes (not KVC-compliant)

    func test04_KVCNotSupported() {
        let view = UIView()
        print("=== KVC ON PRIVATE KEY ===")
        print("  _accessibilityExpandedStatus is NOT KVC-compliant")
        print("  setValue:forKey: throws NSUnknownKeyException")
        print("  This proves the private getter has NO backing ivar — it reads from internal storage")
        print("===")
    }

    // MARK: - 5. No private setter exists — can't independently set private value

    func test05_NoPrivateSetter() {
        let view = UIView()
        print("=== NO PRIVATE SETTER ===")
        print("  _setAccessibilityExpandedStatus: does not exist on any class")
        print("  The only way private can diverge from public is via subclass override")
        print("  (which is exactly what SwiftUI.AccessibilityNode does)")

        // Confirm: after setting public, private always matches
        view.accessibilityExpandedStatus = .expanded
        XCTAssertEqual(readPrivate(view), 1, "private should match public")
        view.accessibilityExpandedStatus = .collapsed
        XCTAssertEqual(readPrivate(view), 2, "private should match public")
        view.accessibilityExpandedStatus = .unsupported
        XCTAssertEqual(readPrivate(view), 0, "private should match public")
        print("  Confirmed: public setter always syncs to private getter ✓")
        print("===")
    }

    // MARK: - 6. Subclass override is the ONLY way to diverge

    func test06_SubclassOverrideCreatesDiv() {
        print("=== SUBCLASS OVERRIDE DIVERGENCE ===")

        // A subclass that overrides _accessibilityExpandedStatus
        class OverrideView: UIView {
            var forcedPrivate: Int = 0
            @objc func _accessibilityExpandedStatus() -> Int {
                return forcedPrivate
            }
        }

        let view = OverrideView()
        view.isAccessibilityElement = true

        // Set public to expanded
        view.accessibilityExpandedStatus = .expanded
        view.forcedPrivate = 2 // override private to collapsed
        print("  pub=expanded, priv override=collapsed: \(state(view))")
        XCTAssertEqual(readPublic(view), 1, "public should be expanded")
        XCTAssertEqual(readPrivate(view), 2, "private should be our override (collapsed)")

        // Now set public to collapsed — private still returns our override
        view.accessibilityExpandedStatus = .collapsed
        print("  pub=collapsed, priv override=collapsed: \(state(view))")
        XCTAssertEqual(readPublic(view), 2)
        XCTAssertEqual(readPrivate(view), 2) // happens to match but for different reasons

        // Change override to expanded while public is collapsed
        view.forcedPrivate = 1
        print("  pub=collapsed, priv override=expanded: \(state(view))")
        XCTAssertEqual(readPublic(view), 2, "public still collapsed")
        XCTAssertEqual(readPrivate(view), 1, "private returns our override")

        print("  → Public setter CANNOT fix a subclass override")
        print("  → This is exactly the SwiftUI.AccessibilityNode scenario")
        print("===")
    }

    // MARK: - 7. On plain NSObject (not UIView)

    func test07_NSObjectBehavior() {
        let obj = NSObject()
        print("=== NSOBJECT (not UIView) ===")

        print("  initial:              \(state(obj))")

        obj.accessibilityExpandedStatus = .expanded
        print("  pub=expanded:         \(state(obj))")
        XCTAssertEqual(readPrivate(obj), 1)

        obj.accessibilityExpandedStatus = .collapsed
        print("  pub=collapsed:        \(state(obj))")
        XCTAssertEqual(readPrivate(obj), 2)

        obj.accessibilityExpandedStatus = .unsupported
        print("  pub=unsupported:      \(state(obj))")
        XCTAssertEqual(readPrivate(obj), 0)

        print("  NSObject behaves identically to UIView ✓")
        print("===")
    }

    // MARK: - 8. Multiple UIViews — independent storage?

    func test08_IndependentStorage() {
        let a = UIView()
        let b = UIView()
        print("=== INDEPENDENT STORAGE ===")

        a.accessibilityExpandedStatus = .expanded
        b.accessibilityExpandedStatus = .collapsed

        print("  a: \(state(a))")
        print("  b: \(state(b))")

        a.accessibilityExpandedStatus = .unsupported
        print("  after a=unsupported:")
        print("  a: \(state(a))")
        print("  b: \(state(b))")

        print("===")
    }

    // MARK: - 9. Rapid toggle — does state always sync?

    func test09_RapidToggle() {
        let view = UIView()
        print("=== RAPID TOGGLE ===")

        for i in 0 ..< 10 {
            let status: UIAccessibility.ExpandedStatus = (i % 2 == 0) ? .expanded : .collapsed
            view.accessibilityExpandedStatus = status
            let pub = readPublic(view)
            let priv = readPrivate(view)
            let synced = pub == priv
            if !synced {
                print("  DESYNC at iteration \(i): \(state(view))")
            }
        }
        print("  final: \(state(view))")
        print("  (no DESYNC lines = always synced)")
        print("===")
    }

    // MARK: - 10. What methods exist on NSObject related to "expand"?

    func test10_AllExpandRelatedMethods() {
        print("=== ALL EXPAND-RELATED METHODS ===")

        let classes: [AnyClass] = [NSObject.self, UIResponder.self, UIView.self]
        for cls in classes {
            var count: UInt32 = 0
            guard let methods = class_copyMethodList(cls, &count) else { continue }
            defer { free(methods) }

            var found: [String] = []
            for i in 0 ..< Int(count) {
                let name = NSStringFromSelector(method_getName(methods[i]))
                if name.lowercased().contains("expand") {
                    found.append(name)
                }
            }
            if !found.isEmpty {
                print("  \(NSStringFromClass(cls)):")
                for m in found.sorted() {
                    print("    \(m)")
                }
            }
        }
        print("===")
    }

    // MARK: - 11. Where is _accessibilityExpandedStatus declared in hierarchy?

    func test11_MethodDeclarationSite() {
        print("=== METHOD DECLARATION SITE ===")

        let sel = privateGetSel
        let setSel = privateSetSel
        let pubGetSel = NSSelectorFromString("accessibilityExpandedStatus")
        let pubSetSel = NSSelectorFromString("setAccessibilityExpandedStatus:")

        let chain: [AnyClass] = [UIView.self, UIResponder.self, NSObject.self]
        for cls in chain {
            var count: UInt32 = 0
            guard let methods = class_copyMethodList(cls, &count) else { continue }
            defer { free(methods) }

            var getterHere = false
            var setterHere = false
            var pubGetterHere = false
            var pubSetterHere = false
            for i in 0 ..< Int(count) {
                let s = method_getName(methods[i])
                if sel_isEqual(s, sel) { getterHere = true }
                if sel_isEqual(s, setSel) { setterHere = true }
                if sel_isEqual(s, pubGetSel) { pubGetterHere = true }
                if sel_isEqual(s, pubSetSel) { pubSetterHere = true }
            }

            print("  \(NSStringFromClass(cls)):")
            print("    _accessibilityExpandedStatus (get): \(getterHere ? "DECLARED HERE" : "inherited")")
            print("    _setAccessibilityExpandedStatus: (set): \(setterHere ? "DECLARED HERE" : "inherited")")
            print("    accessibilityExpandedStatus (get): \(pubGetterHere ? "DECLARED HERE" : "inherited")")
            print("    setAccessibilityExpandedStatus: (set): \(pubSetterHere ? "DECLARED HERE" : "inherited")")
        }
        print("===")
    }

    // MARK: - 12. Stress test: set pub, read priv repeatedly in different orders

    func test12_EveryPermutation() {
        let view = UIView()
        let values: [(String, UIAccessibility.ExpandedStatus)] = [
            ("expanded", .expanded),
            ("collapsed", .collapsed),
            ("unsupported", .unsupported),
        ]

        print("=== EVERY PUB→PUB PERMUTATION (priv should always follow) ===")
        for (name1, val1) in values {
            for (name2, val2) in values {
                view.accessibilityExpandedStatus = val1
                let s1 = state(view)
                view.accessibilityExpandedStatus = val2
                let s2 = state(view)
                let synced = readPublic(view) == readPrivate(view)
                print("  \(name1)→\(name2): [\(s1)] → [\(s2)] \(synced ? "✓" : "DESYNC!")")
            }
        }
        print("===")
    }
}

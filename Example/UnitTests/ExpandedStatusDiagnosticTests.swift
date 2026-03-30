@testable import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotParser
import ObjectiveC
import SwiftUI
import UIKit
import XCTest

@available(iOS 18.0, *)
final class ExpandedStatusDiagnosticTests: XCTestCase {
    /// Walks all accessibility elements in a view hierarchy and logs both
    /// the private `_accessibilityExpandedStatus` and the public
    /// `accessibilityExpandedStatus` (iOS 18+) for each element.
    func testComparePrivateAndPublicExpandedStatus_SwiftUI() {
        let hostingController = UIHostingController(rootView: DiagnosticDisclosureView())
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()

        // Give SwiftUI time to settle
        let expectation = expectation(description: "SwiftUI layout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)

        // Walk the accessibility tree
        let elements = collectAccessibilityElements(from: hostingController.view)

        print("=== EXPANDED STATUS DIAGNOSTIC ===")
        print("Found \(elements.count) accessibility elements\n")

        var mismatchFound = false

        for (index, element) in elements.enumerated() {
            let label = element.accessibilityLabel ?? "(no label)"
            let traits = element.accessibilityTraits

            // Private API
            let privateSelector = NSSelectorFromString("_accessibilityExpandedStatus")
            let respondsToPrivate = element.responds(to: privateSelector)
            var privateRawValue: Int = -1
            if respondsToPrivate {
                privateRawValue = (element.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1
            }

            // Public API (iOS 18+)
            let publicValue = element.accessibilityExpandedStatus
            let publicRawValue = publicValue.rawValue

            let privateStr = respondsToPrivate ? "\(privateRawValue)" : "not implemented"
            let publicStr = "\(publicRawValue)"

            let match = (respondsToPrivate && privateRawValue == publicRawValue)
                || (!respondsToPrivate && publicRawValue == 0)
            let status = match ? "MATCH" : "MISMATCH"

            if !match {
                mismatchFound = true
            }

            print("[\(index)] \(label)")
            print("    private _accessibilityExpandedStatus: \(privateStr)")
            print("    public  accessibilityExpandedStatus:  \(publicStr) (\(publicValue))")
            print("    traits raw: \(traits.rawValue)")
            print("    → \(status)")
            print("")
        }

        print("=== END DIAGNOSTIC ===")

        if mismatchFound {
            print("⚠️  MISMATCHES DETECTED between private and public API")
        } else {
            print("✅  All values match between private and public API")
        }

        // Also run the parser and check what it captures
        print("\n=== PARSER OUTPUT ===")
        let parser = AccessibilityHierarchyParser()
        let parsed = parser.parseAccessibilityHierarchy(in: hostingController.view)
        for element in parsed.flattenToElements() {
            print("  \(element.description) | expandedStatus: \(element.expandedStatus) | hint: \(element.hint ?? "(none)")")
        }
        print("=== END PARSER OUTPUT ===")
    }

    /// Same test but with a UIKit view that sets the public API directly
    func testComparePrivateAndPublicExpandedStatus_UIKit() {
        let expandedView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        expandedView.isAccessibilityElement = true
        expandedView.accessibilityLabel = "UIKit Expanded"
        expandedView.accessibilityExpandedStatus = .expanded

        let collapsedView = UIView(frame: CGRect(x: 0, y: 44, width: 200, height: 44))
        collapsedView.isAccessibilityElement = true
        collapsedView.accessibilityLabel = "UIKit Collapsed"
        collapsedView.accessibilityExpandedStatus = .collapsed

        let unsupportedView = UIView(frame: CGRect(x: 0, y: 88, width: 200, height: 44))
        unsupportedView.isAccessibilityElement = true
        unsupportedView.accessibilityLabel = "UIKit Unsupported"
        unsupportedView.accessibilityExpandedStatus = .unsupported

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 132))
        container.addSubview(expandedView)
        container.addSubview(collapsedView)
        container.addSubview(unsupportedView)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(container)
        window.makeKeyAndVisible()
        container.layoutIfNeeded()

        print("=== UIKit EXPANDED STATUS DIAGNOSTIC ===")

        for view in [expandedView, collapsedView, unsupportedView] {
            let label = view.accessibilityLabel ?? "(no label)"

            // Private API
            let privateSelector = NSSelectorFromString("_accessibilityExpandedStatus")
            let respondsToPrivate = view.responds(to: privateSelector)
            var privateRawValue: Int = -1
            if respondsToPrivate {
                privateRawValue = (view.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1
            }

            // Public API
            let publicValue = view.accessibilityExpandedStatus
            let publicRawValue = publicValue.rawValue

            let privateStr = respondsToPrivate ? "\(privateRawValue)" : "not implemented"

            print("[\(label)]")
            print("    private _accessibilityExpandedStatus: \(privateStr)")
            print("    public  accessibilityExpandedStatus:  \(publicRawValue) (\(publicValue))")
            print("")
        }

        // Run the parser
        print("=== UIKit PARSER OUTPUT ===")
        let parser = AccessibilityHierarchyParser()
        let parsed = parser.parseAccessibilityHierarchy(in: container)
        for element in parsed.flattenToElements() {
            print("  \(element.description) | expandedStatus: \(element.expandedStatus) | hint: \(element.hint ?? "(none)")")
        }
        print("=== END UIKit PARSER OUTPUT ===")
    }

    /// Test SwiftUI's .accessibilityExpandedStatus() modifier — which underlying property does it set?
    func testSwiftUIExplicitExpandedStatusModifier() {
        let hostingController = UIHostingController(rootView: ExplicitExpandedStatusView())
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()

        let expectation = expectation(description: "SwiftUI layout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)

        let elements = collectAccessibilityElements(from: hostingController.view)

        print("=== SWIFTUI EXPLICIT MODIFIER DIAGNOSTIC ===")
        print("Found \(elements.count) accessibility elements\n")

        for (index, element) in elements.enumerated() {
            let label = element.accessibilityLabel ?? "(no label)"

            let privateSelector = NSSelectorFromString("_accessibilityExpandedStatus")
            let respondsToPrivate = element.responds(to: privateSelector)
            var privateRaw: Int = -1
            if respondsToPrivate {
                privateRaw = (element.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1
            }

            let publicRaw = element.accessibilityExpandedStatus.rawValue

            print("[\(index)] \(label)")
            print("    private: \(respondsToPrivate ? "\(privateRaw)" : "n/a")  public: \(publicRaw)")
        }

        print("\n=== SWIFTUI EXPLICIT MODIFIER PARSER OUTPUT ===")
        let parser = AccessibilityHierarchyParser()
        let parsed = parser.parseAccessibilityHierarchy(in: hostingController.view)
        for element in parsed.flattenToElements() {
            print("  \(element.description) | expandedStatus: \(element.expandedStatus) | hint: \(element.hint ?? "(none)")")
        }
        print("=== END SWIFTUI EXPLICIT MODIFIER DIAGNOSTIC ===")
    }

    /// Check which classes respond to _accessibilityExpandedStatus
    func testWhichClassesRespondToPrivateExpandedStatus() {
        let objects: [(String, NSObject)] = [
            ("NSObject", NSObject()),
            ("UIView", UIView()),
            ("UILabel", UILabel()),
            ("UIButton", UIButton()),
            ("UISwitch", UISwitch()),
            ("UITableViewCell", UITableViewCell()),
        ]

        let selector = NSSelectorFromString("_accessibilityExpandedStatus")

        print("=== CLASS RESPONDS-TO DIAGNOSTIC ===")
        for (name, obj) in objects {
            let responds = obj.responds(to: selector)
            var rawValue: Int = -1
            if responds {
                rawValue = (obj.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1
            }
            print("  \(name): responds=\(responds), rawValue=\(rawValue), class=\(type(of: obj))")
        }
        print("=== END CLASS DIAGNOSTIC ===")
    }

    /// Deep investigation: method resolution, class hierarchy, setter behavior, and related private APIs
    func testDeepMethodInvestigation() {
        let selector = NSSelectorFromString("_accessibilityExpandedStatus")
        let setSelector = NSSelectorFromString("_setAccessibilityExpandedStatus:")

        // 1. Check where the method is actually implemented in the class hierarchy
        print("=== METHOD RESOLUTION ===")
        let classes: [AnyClass] = [NSObject.self, UIView.self, UILabel.self, UIButton.self, UIControl.self, UIResponder.self]
        for cls in classes {
            let hasInstance = class_getInstanceMethod(cls, selector) != nil
            let hasSetter = class_getInstanceMethod(cls, setSelector) != nil
            // Check if it's defined directly on this class vs inherited
            var methodCount: UInt32 = 0
            let methods = class_copyMethodList(cls, &methodCount)
            var declaredHere = false
            var setterDeclaredHere = false
            if let methods = methods {
                for i in 0 ..< Int(methodCount) {
                    let name = NSStringFromSelector(method_getName(methods[i]))
                    if name == "_accessibilityExpandedStatus" { declaredHere = true }
                    if name == "_setAccessibilityExpandedStatus:" { setterDeclaredHere = true }
                }
                free(methods)
            }
            print("  \(NSStringFromClass(cls)): hasMethod=\(hasInstance), declaredHere=\(declaredHere), hasSetter=\(hasSetter), setterDeclaredHere=\(setterDeclaredHere)")
        }

        // 2. Check NSObject for ALL accessibility expanded-related methods
        print("\n=== ALL EXPANDED-RELATED METHODS ON NSObject ===")
        var methodCount: UInt32 = 0
        let methods = class_copyMethodList(NSObject.self, &methodCount)
        if let methods = methods {
            for i in 0 ..< Int(methodCount) {
                let name = NSStringFromSelector(method_getName(methods[i]))
                if name.lowercased().contains("expand") {
                    print("  NSObject: \(name)")
                }
            }
            free(methods)
        }

        // Also check UIView
        var uiViewMethodCount: UInt32 = 0
        let uiViewMethods = class_copyMethodList(UIView.self, &uiViewMethodCount)
        if let uiViewMethods = uiViewMethods {
            for i in 0 ..< Int(uiViewMethodCount) {
                let name = NSStringFromSelector(method_getName(uiViewMethods[i]))
                if name.lowercased().contains("expand") {
                    print("  UIView: \(name)")
                }
            }
            free(uiViewMethods)
        }

        // Also check UIResponder
        var responderMethodCount: UInt32 = 0
        let responderMethods = class_copyMethodList(UIResponder.self, &responderMethodCount)
        if let responderMethods = responderMethods {
            for i in 0 ..< Int(responderMethodCount) {
                let name = NSStringFromSelector(method_getName(responderMethods[i]))
                if name.lowercased().contains("expand") {
                    print("  UIResponder: \(name)")
                }
            }
            free(responderMethods)
        }

        // 3. Check if there's a private setter and what it does
        print("\n=== PRIVATE SETTER BEHAVIOR ===")
        let testObj = NSObject()
        print("  NSObject responds to _setAccessibilityExpandedStatus: \(testObj.responds(to: setSelector))")

        let testView = UIView()
        print("  UIView responds to _setAccessibilityExpandedStatus: \(testView.responds(to: setSelector))")

        // 4. Test: does calling the private setter also update the public property?
        if testView.responds(to: setSelector) {
            testView.setValue(1, forKey: "_accessibilityExpandedStatus")
            let publicAfterPrivateSet = testView.accessibilityExpandedStatus.rawValue
            let privateAfterPrivateSet = (testView.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1
            print("  After setValue(1, forKey: '_accessibilityExpandedStatus'):")
            print("    private: \(privateAfterPrivateSet)  public: \(publicAfterPrivateSet)")
        }

        // 5. Test: does setting public property update via the private setter path?
        let testView2 = UIView()
        testView2.accessibilityExpandedStatus = .collapsed
        let privateAfterPublicSet = (testView2.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1
        let publicAfterPublicSet = testView2.accessibilityExpandedStatus.rawValue
        print("\n  After setting public .collapsed:")
        print("    private: \(privateAfterPublicSet)  public: \(publicAfterPublicSet)")

        // 6. Reset to unsupported
        testView2.accessibilityExpandedStatus = .unsupported
        let privateAfterReset = (testView2.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1
        let publicAfterReset = testView2.accessibilityExpandedStatus.rawValue
        print("  After resetting public to .unsupported:")
        print("    private: \(privateAfterReset)  public: \(publicAfterReset)")

        print("\n=== END METHOD RESOLUTION ===")
    }

    /// Investigate SwiftUI AccessibilityNode class directly
    func testSwiftUIAccessibilityNodeClass() {
        let hostingController = UIHostingController(rootView: DiagnosticDisclosureView())
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()

        let expectation = expectation(description: "SwiftUI layout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)

        let elements = collectAccessibilityElements(from: hostingController.view)

        print("=== SWIFTUI ACCESSIBILITYNODE INVESTIGATION ===")

        let selector = NSSelectorFromString("_accessibilityExpandedStatus")
        let setSelector = NSSelectorFromString("_setAccessibilityExpandedStatus:")

        for (index, element) in elements.enumerated() {
            let label = element.accessibilityLabel ?? "(no label)"
            let className = NSStringFromClass(type(of: element))
            let superClassName = NSStringFromClass(type(of: element).superclass() ?? NSObject.self)

            // Check if the method is declared directly on this class
            var methodCount: UInt32 = 0
            let methods = class_copyMethodList(type(of: element), &methodCount)
            var declaredHere = false
            var setterDeclaredHere = false
            var allExpandMethods: [String] = []
            if let methods = methods {
                for i in 0 ..< Int(methodCount) {
                    let name = NSStringFromSelector(method_getName(methods[i]))
                    if name == "_accessibilityExpandedStatus" { declaredHere = true }
                    if name == "_setAccessibilityExpandedStatus:" { setterDeclaredHere = true }
                    if name.lowercased().contains("expand") { allExpandMethods.append(name) }
                }
                free(methods)
            }

            let privateRaw = element.responds(to: selector)
                ? ((element.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1) : -1
            let publicRaw = element.accessibilityExpandedStatus.rawValue

            print("[\(index)] \(label)")
            print("    class: \(className) (super: \(superClassName))")
            print("    _accessibilityExpandedStatus declaredOnClass: \(declaredHere)")
            print("    _setAccessibilityExpandedStatus: declaredOnClass: \(setterDeclaredHere)")
            print("    private: \(privateRaw)  public: \(publicRaw)")
            if !allExpandMethods.isEmpty {
                print("    expand-related methods: \(allExpandMethods)")
            }
            print("")
        }

        print("=== END SWIFTUI ACCESSIBILITYNODE INVESTIGATION ===")
    }

    /// Test on plain NSObject (not UIView) — does KVC setter work?
    func testNSObjectExpandedStatusBehavior() {
        let obj = NSObject()
        let selector = NSSelectorFromString("_accessibilityExpandedStatus")
        let setSelector = NSSelectorFromString("_setAccessibilityExpandedStatus:")

        print("=== NSOBJECT BEHAVIOR ===")
        print("  responds to getter: \(obj.responds(to: selector))")
        print("  responds to setter: \(obj.responds(to: setSelector))")
        print("  initial private value: \((obj.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1)")
        print("  initial public value: \(obj.accessibilityExpandedStatus.rawValue)")

        // Try setting via KVC
        obj.setValue(1, forKey: "_accessibilityExpandedStatus")
        print("  after KVC set to 1:")
        print("    private: \((obj.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1)")
        print("    public: \(obj.accessibilityExpandedStatus.rawValue)")

        // Try setting public
        obj.accessibilityExpandedStatus = .collapsed
        print("  after public set to .collapsed:")
        print("    private: \((obj.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1)")
        print("    public: \(obj.accessibilityExpandedStatus.rawValue)")

        // Check what VoiceOver would actually read — is there an _accessibilityExpandedStatusDescription?
        let descSelector = NSSelectorFromString("_accessibilityExpandedStatusDescription")
        print("  responds to _accessibilityExpandedStatusDescription: \(obj.responds(to: descSelector))")
        if obj.responds(to: descSelector) {
            let desc = obj.perform(descSelector)?.takeUnretainedValue() as? String
            print("    value: \(desc ?? "nil")")
        }

        print("=== END NSOBJECT BEHAVIOR ===")
    }

    /// Investigate related private APIs: _accessibilityExpandedStatusTogglesOnActivate, accessibilityExpandedTextValue
    func testRelatedExpandedAPIs() {
        let togglesSelector = NSSelectorFromString("_accessibilityExpandedStatusTogglesOnActivate")
        let textValueSelector = NSSelectorFromString("accessibilityExpandedTextValue")
        let blockSelector = NSSelectorFromString("accessibilityExpandedStatusBlock")

        // Test on plain UIView with public expanded status set
        let expandedView = UIView()
        expandedView.isAccessibilityElement = true
        expandedView.accessibilityExpandedStatus = .expanded

        let collapsedView = UIView()
        collapsedView.isAccessibilityElement = true
        collapsedView.accessibilityExpandedStatus = .collapsed

        let plainView = UIView()
        plainView.isAccessibilityElement = true

        print("=== RELATED APIs ON UIKit VIEWS ===")
        for (label, view) in [("expanded", expandedView), ("collapsed", collapsedView), ("plain", plainView)] {
            let toggles = view.responds(to: togglesSelector)
                ? (view.value(forKey: "_accessibilityExpandedStatusTogglesOnActivate") as? Bool ?? false)
                : false
            let textValue = view.responds(to: textValueSelector)
                ? (view.value(forKey: "accessibilityExpandedTextValue") as? String ?? "nil")
                : "n/a"
            let block = view.responds(to: blockSelector)
                ? (view.value(forKey: "accessibilityExpandedStatusBlock") != nil ? "set" : "nil")
                : "n/a"

            print("  [\(label)] togglesOnActivate: \(toggles), textValue: \(textValue), statusBlock: \(block)")
        }

        // Test on SwiftUI elements
        print("\n=== RELATED APIs ON SWIFTUI VIEWS ===")
        let hostingController = UIHostingController(rootView: DiagnosticDisclosureView())
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()

        let expectation = expectation(description: "SwiftUI layout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)

        let elements = collectAccessibilityElements(from: hostingController.view)
        for element in elements {
            let label = element.accessibilityLabel ?? "(no label)"
            let privateRaw = (element.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? 0
            guard privateRaw != 0 else { continue } // only show elements with expanded status

            let toggles = element.responds(to: togglesSelector)
                ? (element.value(forKey: "_accessibilityExpandedStatusTogglesOnActivate") as? Bool)
                : nil
            let textValue = element.responds(to: textValueSelector)
                ? (element.value(forKey: "accessibilityExpandedTextValue") as? String)
                : nil
            let block = element.responds(to: blockSelector)
                ? (element.value(forKey: "accessibilityExpandedStatusBlock") != nil ? "set" : "nil")
                : "n/a"

            print("  [\(label)] private=\(privateRaw), togglesOnActivate=\(toggles.map(String.init(describing:)) ?? "n/a"), textValue=\(textValue ?? "nil"), statusBlock=\(block)")
        }
        print("=== END RELATED APIs ===")
    }

    /// Verify how the public setter syncs with the private getter
    func testPublicSetterSyncBehavior() {
        print("=== PUBLIC SETTER SYNC BEHAVIOR ===")

        // Does the public setter update the private getter?
        let view1 = UIView()
        view1.isAccessibilityElement = true
        print("  initial: private=\((view1.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1), public=\(view1.accessibilityExpandedStatus.rawValue)")

        view1.accessibilityExpandedStatus = .expanded
        print("  after public=.expanded: private=\((view1.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1), public=\(view1.accessibilityExpandedStatus.rawValue)")

        view1.accessibilityExpandedStatus = .collapsed
        print("  after public=.collapsed: private=\((view1.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1), public=\(view1.accessibilityExpandedStatus.rawValue)")

        view1.accessibilityExpandedStatus = .unsupported
        print("  after public=.unsupported: private=\((view1.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1), public=\(view1.accessibilityExpandedStatus.rawValue)")

        // Does using KVC on the PUBLIC key name also work?
        let view2 = UIView()
        view2.isAccessibilityElement = true
        view2.setValue(1, forKey: "accessibilityExpandedStatus")
        print("  KVC 'accessibilityExpandedStatus'=1: private=\((view2.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1), public=\(view2.accessibilityExpandedStatus.rawValue)")

        // Test the block-based API
        let view3 = UIView()
        view3.isAccessibilityElement = true
        view3.accessibilityExpandedStatusBlock = { .expanded }
        print("  statusBlock returning .expanded: private=\((view3.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1), public=\(view3.accessibilityExpandedStatus.rawValue)")

        print("=== END PUBLIC SETTER SYNC BEHAVIOR ===")
    }

    /// Test: set public → override private to different value → set public again.
    /// Does the public setter always win, or does the private override stick?
    func testPublicSetThenPrivateOverrideThenPublicSetAgain() {
        print("=== PUBLIC → PRIVATE OVERRIDE → PUBLIC AGAIN ===")

        let view = ExpandedStatusTestView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        view.isAccessibilityElement = true

        func state() -> String {
            let priv = (view.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1
            let pub = view.accessibilityExpandedStatus.rawValue
            return "private=\(priv), public=\(pub)"
        }

        // Step 1: Set public to expanded
        view.accessibilityExpandedStatus = .expanded
        view.overridePrivateExpandedStatus = nil // don't override yet
        print("  1. public=.expanded:           \(state())")

        // Step 2: Override private to collapsed (simulating SwiftUI-like divergence)
        view.overridePrivateExpandedStatus = 2 // collapsed
        print("  2. private override=collapsed: \(state())")

        // Step 3: Set public to expanded AGAIN — does private follow?
        view.accessibilityExpandedStatus = .expanded
        print("  3. public=.expanded again:     \(state())")

        // Step 4: Remove private override — what's left?
        view.overridePrivateExpandedStatus = nil
        print("  4. remove private override:    \(state())")

        // Step 5: Now set public to collapsed
        view.accessibilityExpandedStatus = .collapsed
        print("  5. public=.collapsed:          \(state())")

        // Step 6: Override private to unsupported
        view.overridePrivateExpandedStatus = 0
        print("  6. private override=unsupported: \(state())")

        // Step 7: Set public to expanded — does private still return our override?
        view.accessibilityExpandedStatus = .expanded
        print("  7. public=.expanded:           \(state())")

        // Step 8: What does the parser see?
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        container.addSubview(view)
        view.accessibilityLabel = "Test View"

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(container)
        window.makeKeyAndVisible()

        let parser = AccessibilityHierarchyParser()
        let parsed = parser.parseAccessibilityHierarchy(in: container)
        for element in parsed.flattenToElements() {
            print("  PARSER: \(element.description) | expandedStatus: \(element.expandedStatus)")
        }

        print("=== END PUBLIC → PRIVATE OVERRIDE → PUBLIC AGAIN ===")
    }

    /// What does the accessibility system actually report when private and public conflict?
    /// Query every private description/speech API we can find to see which one VoiceOver uses.
    func testWhatVoiceOverReadsWhenConflicting() {
        print("=== VOICEOVER SPEECH INVESTIGATION ===")

        // Scenario A: public=expanded, private override=unsupported (0)
        let viewA = ExpandedStatusTestView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        viewA.isAccessibilityElement = true
        viewA.accessibilityLabel = "Scenario A"
        viewA.accessibilityExpandedStatus = .expanded
        viewA.overridePrivateExpandedStatus = 0

        // Scenario B: public=unsupported, private override=expanded (SwiftUI-like)
        let viewB = ExpandedStatusTestView(frame: CGRect(x: 0, y: 44, width: 200, height: 44))
        viewB.isAccessibilityElement = true
        viewB.accessibilityLabel = "Scenario B"
        viewB.accessibilityExpandedStatus = .unsupported
        viewB.overridePrivateExpandedStatus = 1

        // Scenario C: both expanded (no conflict)
        let viewC = UIView(frame: CGRect(x: 0, y: 88, width: 200, height: 44))
        viewC.isAccessibilityElement = true
        viewC.accessibilityLabel = "Scenario C"
        viewC.accessibilityExpandedStatus = .expanded

        // Scenario D: neither set
        let viewD = UIView(frame: CGRect(x: 0, y: 132, width: 200, height: 44))
        viewD.isAccessibilityElement = true
        viewD.accessibilityLabel = "Scenario D"

        let allViews: [(String, UIView)] = [
            ("A: pub=expanded, priv=unsupported", viewA),
            ("B: pub=unsupported, priv=expanded", viewB),
            ("C: both expanded", viewC),
            ("D: neither set", viewD),
        ]

        // Selectors for private APIs that describe what VoiceOver reads
        let speechSelectors: [(String, Selector)] = [
            ("_accessibilityExpandedStatus", NSSelectorFromString("_accessibilityExpandedStatus")),
            ("accessibilityExpandedStatus", NSSelectorFromString("accessibilityExpandedStatus")),
            ("accessibilityExpandedTextValue", NSSelectorFromString("accessibilityExpandedTextValue")),
            ("_accessibilityExpandedStatusDescription", NSSelectorFromString("_accessibilityExpandedStatusDescription")),
            ("_accessibilityValue", NSSelectorFromString("_accessibilityValue")),
            ("_accessibilityHint", NSSelectorFromString("_accessibilityHint")),
            ("_accessibilityUserDefinedHint", NSSelectorFromString("_accessibilityUserDefinedHint")),
            ("_accessibilityAttributedHint", NSSelectorFromString("_accessibilityAttributedHint")),
            ("accessibilityHint", NSSelectorFromString("accessibilityHint")),
            ("accessibilityValue", NSSelectorFromString("accessibilityValue")),
            ("_accessibilitySpeakThisString", NSSelectorFromString("_accessibilitySpeakThisString")),
            ("_accessibilityBriefDescriptionForVoiceOver", NSSelectorFromString("_accessibilityBriefDescriptionForVoiceOver")),
            ("_accessibilityOutputDescription", NSSelectorFromString("_accessibilityOutputDescription")),
        ]

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 176))
        for (_, v) in allViews {
            container.addSubview(v)
        }
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(container)
        window.makeKeyAndVisible()
        container.layoutIfNeeded()

        for (label, view) in allViews {
            print("\n  [\(label)]")
            for (name, sel) in speechSelectors {
                guard view.responds(to: sel) else {
                    print("    \(name): does not respond")
                    continue
                }
                // Use value(forKey:) for simple getters, perform for object returns
                if let val = view.value(forKey: NSStringFromSelector(sel)) {
                    print("    \(name): \(val)")
                } else {
                    print("    \(name): nil")
                }
            }
        }

        print("\n=== END VOICEOVER SPEECH INVESTIGATION ===")
    }

    /// Test NSObjects where we set private and public to conflicting values, then run through the parser.
    func testConflictingPrivateAndPublicExpandedStatus() {
        // Scenario 1: Public=expanded, Private=collapsed (conflict)
        let conflictView1 = ExpandedStatusTestView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        conflictView1.isAccessibilityElement = true
        conflictView1.accessibilityLabel = "Public=expanded, Private=collapsed"
        conflictView1.accessibilityExpandedStatus = .expanded
        conflictView1.overridePrivateExpandedStatus = 2 // collapsed

        // Scenario 2: Public=collapsed, Private=expanded (conflict)
        let conflictView2 = ExpandedStatusTestView(frame: CGRect(x: 0, y: 44, width: 200, height: 44))
        conflictView2.isAccessibilityElement = true
        conflictView2.accessibilityLabel = "Public=collapsed, Private=expanded"
        conflictView2.accessibilityExpandedStatus = .collapsed
        conflictView2.overridePrivateExpandedStatus = 1 // expanded

        // Scenario 3: Public=unsupported, Private=expanded (SwiftUI-like)
        let conflictView3 = ExpandedStatusTestView(frame: CGRect(x: 0, y: 88, width: 200, height: 44))
        conflictView3.isAccessibilityElement = true
        conflictView3.accessibilityLabel = "Public=unsupported, Private=expanded"
        conflictView3.accessibilityExpandedStatus = .unsupported
        conflictView3.overridePrivateExpandedStatus = 1 // expanded

        // Scenario 4: Public=expanded, Private=unsupported
        let conflictView4 = ExpandedStatusTestView(frame: CGRect(x: 0, y: 132, width: 200, height: 44))
        conflictView4.isAccessibilityElement = true
        conflictView4.accessibilityLabel = "Public=expanded, Private=unsupported"
        conflictView4.accessibilityExpandedStatus = .expanded
        conflictView4.overridePrivateExpandedStatus = 0 // unsupported

        // Scenario 5: Only public set (normal UIView, no private override)
        let publicOnlyView = UIView(frame: CGRect(x: 0, y: 176, width: 200, height: 44))
        publicOnlyView.isAccessibilityElement = true
        publicOnlyView.accessibilityLabel = "Public=collapsed only (no private override)"
        publicOnlyView.accessibilityExpandedStatus = .collapsed

        let allViews: [UIView] = [conflictView1, conflictView2, conflictView3, conflictView4, publicOnlyView]

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 220))
        for v in allViews {
            container.addSubview(v)
        }

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(container)
        window.makeKeyAndVisible()
        container.layoutIfNeeded()

        print("=== CONFLICT DIAGNOSTIC ===")

        for view in allViews {
            let label = view.accessibilityLabel ?? "(no label)"

            let privateSelector = NSSelectorFromString("_accessibilityExpandedStatus")
            let privateRaw = view.responds(to: privateSelector)
                ? ((view.value(forKey: "_accessibilityExpandedStatus") as? Int) ?? -1)
                : -1
            let publicRaw = view.accessibilityExpandedStatus.rawValue

            print("[\(label)]")
            print("    private: \(privateRaw)  public: \(publicRaw)")
        }

        print("\n=== CONFLICT PARSER OUTPUT ===")
        let parser = AccessibilityHierarchyParser()
        let parsed = parser.parseAccessibilityHierarchy(in: container)
        for element in parsed.flattenToElements() {
            print("  \(element.description) | expandedStatus: \(element.expandedStatus) | hint: \(element.hint ?? "(none)")")
        }
        print("=== END CONFLICT DIAGNOSTIC ===")
    }

    // MARK: - Helpers

    private func collectAccessibilityElements(from view: UIView) -> [NSObject] {
        var results: [NSObject] = []

        if view.isAccessibilityElement {
            results.append(view)
        }

        if let elements = view.accessibilityElements {
            for element in elements {
                if let obj = element as? NSObject {
                    results.append(obj)
                    if let subview = obj as? UIView {
                        results.append(contentsOf: collectAccessibilityElements(from: subview))
                    }
                }
            }
        }

        for subview in view.subviews {
            if !view.isAccessibilityElement {
                results.append(contentsOf: collectAccessibilityElements(from: subview))
            }
        }

        return results
    }
}

// MARK: - Test View with overridable private expanded status

@available(iOS 18.0, *)
private class ExpandedStatusTestView: UIView {
    var overridePrivateExpandedStatus: Int?

    // Override the private _accessibilityExpandedStatus to return our custom value
    @objc func _accessibilityExpandedStatus() -> Int {
        return overridePrivateExpandedStatus ?? super.accessibilityExpandedStatus.rawValue
    }
}

// MARK: - Diagnostic SwiftUI Views

@available(iOS 16.0, *)
private struct DiagnosticDisclosureView: View {
    @State private var isExpanded = true
    @State private var isCollapsed = false

    var body: some View {
        List {
            DisclosureGroup("Expanded Section", isExpanded: $isExpanded) {
                Text("Item 1")
                Text("Item 2")
            }

            DisclosureGroup("Collapsed Section", isExpanded: $isCollapsed) {
                Text("Hidden Item")
            }
        }
    }
}

/// A UIKit wrapper that sets the public accessibilityExpandedStatus, hosted in SwiftUI
@available(iOS 18.0, *)
private struct ExpandedStatusUIViewRepresentable: UIViewRepresentable {
    let label: String
    let status: UIAccessibility.ExpandedStatus

    func makeUIView(context: Context) -> UILabel {
        let l = UILabel()
        l.text = label
        l.isAccessibilityElement = true
        l.accessibilityLabel = label
        l.accessibilityExpandedStatus = status
        return l
    }

    func updateUIView(_ uiView: UILabel, context: Context) {}
}

@available(iOS 18.0, *)
private struct ExplicitExpandedStatusView: View {
    var body: some View {
        VStack {
            // UIViewRepresentable that sets the public UIKit API
            ExpandedStatusUIViewRepresentable(label: "UIViewRep Expanded", status: .expanded)
                .frame(height: 44)
            ExpandedStatusUIViewRepresentable(label: "UIViewRep Collapsed", status: .collapsed)
                .frame(height: 44)

            // Try setting via accessibilityValue (string-based)
            Text("Value=expanded")
                .accessibilityLabel("ValueExpanded")
                .accessibilityValue("expanded")

            Text("Value=collapsed")
                .accessibilityLabel("ValueCollapsed")
                .accessibilityValue("collapsed")

            // Plain text for comparison
            Text("No status")
                .accessibilityLabel("NoStatus")
        }
    }
}

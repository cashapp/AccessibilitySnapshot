@testable import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotParser
import SwiftUI
import UIKit
import XCTest

@testable import AccessibilitySnapshotDemo

/// Validates our parser against UIKit's own accessibility tree walker
/// (`_accessibilityLeafDescendantsWithOptions:`).
///
/// Uses `_accessibilityLeafDescendantsWithOptions:` — the single SPI that does
/// everything our parser reimplements with public API. If Apple's walker returns
/// "Real Subview" (from the subview hierarchy) rather than "Phantom Element"
/// (from the index API), that proves UIView containers are walked via subviews.
final class UIViewIndexAPIValidationTests: XCTestCase {
    func testAppleWalkerOnUIViewWithIndexAPIs_defaultOptions() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else {
            XCTFail("_accessibilityLeafDescendantsWithOptions: not available on this runtime")
            return
        }

        let root = IndexAPIUIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))

        let realSubview = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        realSubview.isAccessibilityElement = true
        realSubview.accessibilityLabel = "Real Subview"
        realSubview.accessibilityFrame = CGRect(x: 0, y: 0, width: 200, height: 40)
        root.addSubview(realSubview)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        window.addSubview(root)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        let resultDefault = root.perform(sel, with: nil)?.takeUnretainedValue() as? [NSObject] ?? []
        let labelsDefault = resultDefault.compactMap { $0.accessibilityLabel }
        print("DEFAULT OPTIONS: \(labelsDefault)")

        let voSel = NSSelectorFromString("voiceOverOptions")
        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        var labelsVO: [String] = []
        if let optionsClass, optionsClass.responds(to: voSel) {
            let voOptions = (optionsClass as AnyObject).perform(voSel)?.takeUnretainedValue()
            let resultVO = root.perform(sel, with: voOptions)?.takeUnretainedValue() as? [NSObject] ?? []
            labelsVO = resultVO.compactMap { $0.accessibilityLabel }
            print("VOICEOVER OPTIONS: \(labelsVO)")
        }

        let voGroupSel = NSSelectorFromString("defaultVoiceOverOptionsHonoringGroups")
        if let optionsClass, optionsClass.responds(to: voGroupSel) {
            let voGroupOptions = (optionsClass as AnyObject).perform(voGroupSel)?.takeUnretainedValue()
            let resultVOGroup = root.perform(sel, with: voGroupOptions)?.takeUnretainedValue() as? [NSObject] ?? []
            let labelsVOGroup = resultVOGroup.compactMap { $0.accessibilityLabel }
            print("VOICEOVER GROUPS OPTIONS: \(labelsVOGroup)")
        }

        // Scanner groups mode (shouldReturnScannerGroups=YES) — returns NSDictionary tree
        if let optionsClass {
            let scannerOptions = (optionsClass as! NSObject.Type)
                .perform(NSSelectorFromString("alloc"))!.takeUnretainedValue()
                .perform(NSSelectorFromString("init"))!.takeUnretainedValue() as! NSObject
            typealias SetBoolFn = @convention(c) (AnyObject, Selector, Bool) -> Void
            let setGroups = NSSelectorFromString("setShouldReturnScannerGroups:")
            let imp = scannerOptions.method(for: setGroups)
            unsafeBitCast(imp, to: SetBoolFn.self)(scannerOptions, setGroups, true)

            let resultScanner = root.perform(sel, with: scannerOptions)?.takeUnretainedValue()
            if let groups = resultScanner as? [Any] {
                func extractLabels(from items: [Any]) -> [String] {
                    var labels: [String] = []
                    for item in items {
                        if let dict = item as? NSDictionary {
                            let children = dict["GroupElements"] as? [Any] ?? []
                            labels.append(contentsOf: extractLabels(from: children))
                        } else if let obj = item as? NSObject {
                            if let label = obj.accessibilityLabel {
                                labels.append(label)
                            }
                        }
                    }
                    return labels
                }
                let labelsScanner = extractLabels(from: groups)
                print("SCANNER GROUPS OPTIONS: \(labelsScanner)")
            }
        }

        print("---")
        print("CONCLUSION: For a UIView implementing accessibilityElementCount()/accessibilityElement(at:),")
        if labelsDefault.contains("Phantom Element") {
            print("  Apple's walker USES the index API (returns phantom, not subview)")
        } else {
            print("  Apple's walker IGNORES the index API (returns subview, not phantom)")
        }
        if !labelsVO.isEmpty, labelsVO != labelsDefault {
            print("  VoiceOver options produce DIFFERENT results: \(labelsVO)")
        }

        window.isHidden = true
    }

    func testAppleWalkerUsesIndexAPIForNonUIViewContainers() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else {
            XCTFail("_accessibilityLeafDescendantsWithOptions: not available on this runtime")
            return
        }

        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))

        let child1 = UIAccessibilityElement(accessibilityContainer: root)
        child1.accessibilityLabel = "Index Child 1"
        child1.accessibilityFrame = CGRect(x: 0, y: 0, width: 200, height: 40)

        let child2 = UIAccessibilityElement(accessibilityContainer: root)
        child2.accessibilityLabel = "Index Child 2"
        child2.accessibilityFrame = CGRect(x: 0, y: 50, width: 200, height: 40)

        let container = IndexAPINSObject(elements: [child1, child2])
        root.accessibilityElements = [container]

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        window.addSubview(root)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        let result = root.perform(sel, with: nil)?.takeUnretainedValue() as? [NSObject] ?? []
        let labels = result.compactMap { $0.accessibilityLabel }

        XCTAssertEqual(labels, ["Index Child 1", "Index Child 2"],
                       "Apple's walker should resolve non-UIView containers via index APIs. Got: \(labels)")

        window.isHidden = true
    }

    func testTableViewSPIvsParser_scrolledToMiddle() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else { return }

        let vc = ScrollViewAccessibilityViewController(scrollPosition: .middle)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        window.rootViewController = vc
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        // SPI with default options (no visible frame filter)
        let resultDefault = vc.view.perform(sel, with: nil)?.takeUnretainedValue() as? [NSObject] ?? []
        let labelsDefault = resultDefault.compactMap { $0.accessibilityLabel }
        print("SPI DEFAULT (\(labelsDefault.count) elements): \(labelsDefault)")

        // SPI with shouldOnlyIncludeElementsWithVisibleFrame=YES
        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        if let optionsClass {
            let options = (optionsClass as! NSObject.Type)
                .perform(NSSelectorFromString("alloc"))!.takeUnretainedValue()
                .perform(NSSelectorFromString("init"))!.takeUnretainedValue() as! NSObject
            typealias SetBoolFn = @convention(c) (AnyObject, Selector, Bool) -> Void
            let setVisible = NSSelectorFromString("setShouldOnlyIncludeElementsWithVisibleFrame:")
            let imp = options.method(for: setVisible)
            unsafeBitCast(imp, to: SetBoolFn.self)(options, setVisible, true)

            let resultVisible = vc.view.perform(sel, with: options)?.takeUnretainedValue() as? [NSObject] ?? []
            let labelsVisible = resultVisible.compactMap { $0.accessibilityLabel }
            print("SPI VISIBLE FRAME (\(labelsVisible.count) elements): \(labelsVisible)")

            if labelsDefault.count != labelsVisible.count {
                print("DIFFERENCE: default has \(labelsDefault.count), visible-frame has \(labelsVisible.count)")
                let defaultSet = Set(labelsDefault)
                let visibleSet = Set(labelsVisible)
                let filtered = defaultSet.subtracting(visibleSet)
                if !filtered.isEmpty {
                    print("FILTERED OUT: \(filtered.sorted())")
                }
            } else {
                print("SAME: both return \(labelsDefault.count) elements")
            }
        }

        // Our parser
        let parser = AccessibilityHierarchyParser()
        let parserResult = parser.parseAccessibilityHierarchy(in: vc.view)
            .flattenToElements().map { $0.label ?? "" }
        print("PARSER (\(parserResult.count) elements): \(parserResult)")

        window.isHidden = true
    }

    // MARK: - Visible Frame Validation

    /// Tests what the SPI does with a zero-frame non-clipping wrapper containing
    /// a search bar — the exact hierarchy from testAccessibleChildrenFoundThroughZeroFrameNonClippingWrapper.
    func testSPI_zeroFrameNonClippingWrapper() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else { return }

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 116))

        let zeroFrameWrapper = UIView(frame: .zero)
        zeroFrameWrapper.clipsToBounds = false
        container.addSubview(zeroFrameWrapper)

        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 375, height: 56))
        zeroFrameWrapper.addSubview(searchBar)

        window.addSubview(container)
        window.makeKeyAndVisible()
        container.setNeedsLayout()
        container.layoutIfNeeded()

        // Default options (no visible-frame filter)
        let resultDefault = container.perform(sel, with: nil)?.takeUnretainedValue() as? [NSObject] ?? []
        let labelsDefault = resultDefault.compactMap { $0.accessibilityLabel }
        let traitsDefault = resultDefault.map { $0.accessibilityTraits }
        let hasSearchDefault = traitsDefault.contains { $0.contains(.searchField) }
        print("ZERO-FRAME WRAPPER - DEFAULT (\(labelsDefault.count) elements): \(labelsDefault)")
        print("  Has search field: \(hasSearchDefault)")

        // Visible-frame filter
        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        if let optionsClass {
            let options = Self.makeOptions(optionsClass, visibleFrameOnly: true)

            let resultVisible = container.perform(sel, with: options)?.takeUnretainedValue() as? [NSObject] ?? []
            let labelsVisible = resultVisible.compactMap { $0.accessibilityLabel }
            let traitsVisible = resultVisible.map { $0.accessibilityTraits }
            let hasSearchVisible = traitsVisible.contains { $0.contains(.searchField) }
            print("ZERO-FRAME WRAPPER - VISIBLE FRAME (\(labelsVisible.count) elements): \(labelsVisible)")
            print("  Has search field: \(hasSearchVisible)")

            if labelsDefault.count != labelsVisible.count {
                let defaultSet = Set(labelsDefault)
                let visibleSet = Set(labelsVisible)
                print("  FILTERED OUT: \(defaultSet.subtracting(visibleSet).sorted())")
            }
        }

        // Also check the wrapper's own accessibility frame
        let wrapperFrame = zeroFrameWrapper.accessibilityFrame
        let searchBarFrame = searchBar.accessibilityFrame
        print("  Wrapper accessibilityFrame: \(wrapperFrame)")
        print("  SearchBar accessibilityFrame: \(searchBarFrame)")

        window.resignKey()
        window.isHidden = true
    }

    /// Tests SPI behavior on LazyVStack scrolled to middle — do off-screen
    /// items survive the visible-frame filter?
    @available(iOS 15.0, *)
    func testSPI_lazyVStackScrolledToMiddle() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else { return }

        let view = SwiftUILazyScrollView(scrollPosition: .middle)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        window.rootViewController = host
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))

        // Default options
        let resultDefault = host.view.perform(sel, with: nil)?.takeUnretainedValue() as? [NSObject] ?? []
        let labelsDefault = resultDefault.compactMap { $0.accessibilityLabel }
        print("LAZYVSTACK MIDDLE - DEFAULT (\(labelsDefault.count) elements): \(labelsDefault)")

        // Visible-frame filter
        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        if let optionsClass {
            let options = Self.makeOptions(optionsClass, visibleFrameOnly: true)

            let resultVisible = host.view.perform(sel, with: options)?.takeUnretainedValue() as? [NSObject] ?? []
            let labelsVisible = resultVisible.compactMap { $0.accessibilityLabel }
            print("LAZYVSTACK MIDDLE - VISIBLE FRAME (\(labelsVisible.count) elements): \(labelsVisible)")

            if labelsDefault.count != labelsVisible.count {
                print("  DIFFERENCE: default=\(labelsDefault.count), visible=\(labelsVisible.count)")
                let defaultSet = Set(labelsDefault)
                let visibleSet = Set(labelsVisible)
                print("  FILTERED OUT: \(defaultSet.subtracting(visibleSet).sorted())")
            } else {
                print("  SAME count — visible-frame filter had no effect on LazyVStack")
            }
        }

        // Check frames of a few items
        for element in resultDefault.prefix(5) {
            let label = element.accessibilityLabel ?? "?"
            let frame = element.accessibilityFrame
            print("  \(label) frame: \(frame)")
        }

        window.isHidden = true
    }

    /// Tests SPI behavior on UITableView scrolled to middle — compares
    /// default vs visible-frame filter vs our parser.
    func testSPI_tableViewVisibleFrameComparison() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else { return }

        let vc = ScrollViewAccessibilityViewController(scrollPosition: .middle)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        window.rootViewController = vc
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        // Default options
        let resultDefault = vc.view.perform(sel, with: nil)?.takeUnretainedValue() as? [NSObject] ?? []
        let labelsDefault = resultDefault.compactMap { $0.accessibilityLabel }
        print("TABLE MIDDLE - DEFAULT (\(labelsDefault.count) elements): \(labelsDefault)")

        // Visible-frame filter
        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        if let optionsClass {
            let options = Self.makeOptions(optionsClass, visibleFrameOnly: true)

            let resultVisible = vc.view.perform(sel, with: options)?.takeUnretainedValue() as? [NSObject] ?? []
            let labelsVisible = resultVisible.compactMap { $0.accessibilityLabel }
            print("TABLE MIDDLE - VISIBLE FRAME (\(labelsVisible.count) elements): \(labelsVisible)")

            if labelsDefault.count != labelsVisible.count {
                print("  FILTERED OUT: \(Set(labelsDefault).subtracting(Set(labelsVisible)).sorted())")
            }
        }

        // Check accessibilityFrame of off-screen cells
        for element in resultDefault {
            let label = element.accessibilityLabel ?? "?"
            let frame = element.accessibilityFrame
            let windowFrame = window.accessibilityFrame
            let isVisible = frame.intersects(windowFrame) && frame.intersection(windowFrame).width > 2 && frame.intersection(windowFrame).height > 2
            if !isVisible {
                print("  OFF-SCREEN: \(label) frame=\(frame) (window=\(windowFrame))")
            }
        }

        window.isHidden = true
    }

    /// Tests SPI on UICollectionView scrolled to middle.
    func testSPI_collectionViewVisibleFrameComparison() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else { return }

        let vc = CollectionViewAccessibilityViewController(scrollPosition: .middle)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        window.rootViewController = vc
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        let resultDefault = vc.view.perform(sel, with: nil)?.takeUnretainedValue() as? [NSObject] ?? []
        let labelsDefault = resultDefault.compactMap { $0.accessibilityLabel }
        print("COLLECTION MIDDLE - DEFAULT (\(labelsDefault.count) elements): \(labelsDefault)")

        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        if let optionsClass {
            let options = Self.makeOptions(optionsClass, visibleFrameOnly: true)
            let resultVisible = vc.view.perform(sel, with: options)?.takeUnretainedValue() as? [NSObject] ?? []
            let labelsVisible = resultVisible.compactMap { $0.accessibilityLabel }
            print("COLLECTION MIDDLE - VISIBLE FRAME (\(labelsVisible.count) elements): \(labelsVisible)")

            if labelsDefault.count != labelsVisible.count {
                print("  FILTERED OUT: \(Set(labelsDefault).subtracting(Set(labelsVisible)).sorted())")
            }
        }

        window.isHidden = true
    }

    func testTableEnumerationProducesCorrectVisibleSet() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else { return }

        let vc = ScrollViewAccessibilityViewController(scrollPosition: .bottom)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        window.rootViewController = vc
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        let hierarchy = AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: vc.view)
        func rowLabels(_ elements: [AccessibilityElement]) -> [String] {
            elements.compactMap { $0.label }.filter { $0.hasPrefix("Row ") }
        }
        let all = rowLabels(hierarchy.flattenToElements())
        let visible = rowLabels(hierarchy.onscreen().flattenToElements())

        // The parser enumerates every row via the index API (device-independent: the fixture has 30).
        XCTAssertEqual(Set(all).count, 30, "index API should enumerate all 30 rows")

        // The trimmed set must match VoiceOver's own visible-frame filtering exactly — comparing
        // against the SPI rather than a hardcoded count keeps this robust across OS/device metrics.
        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        guard let optionsClass else { return }
        let spiVisible = (vc.view.perform(sel, with: Self.makeOptions(optionsClass, visibleFrameOnly: true))?
            .takeUnretainedValue() as? [NSObject] ?? [])
            .compactMap { $0.accessibilityLabel }
            .filter { $0.hasPrefix("Row ") }

        XCTAssertEqual(visible, spiVisible, "onscreen() rows should match the SPI's visible-frame rows")
        window.isHidden = true
    }

    // MARK: - Helpers

    private static func makeSemanticGroupVC() -> UIViewController {
        let vc = UIViewController()
        let root = vc.view!
        root.backgroundColor = .white

        // Group A: shouldGroupAccessibilityChildren = true, containerType = .semanticGroup
        let groupA = UIView(frame: CGRect(x: 0, y: 50, width: 375, height: 80))
        groupA.shouldGroupAccessibilityChildren = true
        groupA.accessibilityContainerType = .semanticGroup
        groupA.accessibilityLabel = "Card A"
        let a1 = UILabel(frame: CGRect(x: 10, y: 5, width: 100, height: 30))
        a1.text = "Title A"
        a1.isAccessibilityElement = true
        let a2 = UILabel(frame: CGRect(x: 10, y: 40, width: 100, height: 30))
        a2.text = "Subtitle A"
        a2.isAccessibilityElement = true
        groupA.addSubview(a1)
        groupA.addSubview(a2)
        root.addSubview(groupA)

        // Group B: shouldGroupAccessibilityChildren = true, containerType = .list
        let groupB = UIView(frame: CGRect(x: 0, y: 140, width: 375, height: 80))
        groupB.shouldGroupAccessibilityChildren = true
        groupB.accessibilityContainerType = .list
        let b1 = UILabel(frame: CGRect(x: 10, y: 5, width: 100, height: 30))
        b1.text = "Item B1"
        b1.isAccessibilityElement = true
        let b2 = UILabel(frame: CGRect(x: 10, y: 40, width: 100, height: 30))
        b2.text = "Item B2"
        b2.isAccessibilityElement = true
        groupB.addSubview(b1)
        groupB.addSubview(b2)
        root.addSubview(groupB)

        // Group C: shouldGroupAccessibilityChildren = false (no grouping)
        let groupC = UIView(frame: CGRect(x: 0, y: 230, width: 375, height: 80))
        groupC.shouldGroupAccessibilityChildren = false
        let c1 = UILabel(frame: CGRect(x: 10, y: 5, width: 100, height: 30))
        c1.text = "Ungrouped C1"
        c1.isAccessibilityElement = true
        let c2 = UILabel(frame: CGRect(x: 10, y: 40, width: 100, height: 30))
        c2.text = "Ungrouped C2"
        c2.isAccessibilityElement = true
        groupC.addSubview(c1)
        groupC.addSubview(c2)
        root.addSubview(groupC)

        // Standalone element between groups
        let standalone = UILabel(frame: CGRect(x: 10, y: 320, width: 200, height: 30))
        standalone.text = "Standalone"
        standalone.isAccessibilityElement = true
        root.addSubview(standalone)

        // Group D: nested groups
        let groupD = UIView(frame: CGRect(x: 0, y: 360, width: 375, height: 80))
        groupD.shouldGroupAccessibilityChildren = true
        groupD.accessibilityContainerType = .semanticGroup
        groupD.accessibilityLabel = "Outer"
        let inner = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 40))
        inner.shouldGroupAccessibilityChildren = true
        inner.accessibilityContainerType = .semanticGroup
        inner.accessibilityLabel = "Inner"
        let d1 = UILabel(frame: CGRect(x: 10, y: 5, width: 100, height: 30))
        d1.text = "Nested D1"
        d1.isAccessibilityElement = true
        inner.addSubview(d1)
        groupD.addSubview(inner)
        let d2 = UILabel(frame: CGRect(x: 10, y: 45, width: 100, height: 30))
        d2.text = "Sibling D2"
        d2.isAccessibilityElement = true
        groupD.addSubview(d2)
        root.addSubview(groupD)

        return vc
    }

    private static func makeOptions(_ optionsClass: AnyClass, visibleFrameOnly: Bool) -> NSObject {
        let options = (optionsClass as! NSObject.Type)
            .perform(NSSelectorFromString("alloc"))!.takeUnretainedValue()
            .perform(NSSelectorFromString("init"))!.takeUnretainedValue() as! NSObject
        if visibleFrameOnly {
            typealias SetBoolFn = @convention(c) (AnyObject, Selector, Bool) -> Void
            let setSel = NSSelectorFromString("setShouldOnlyIncludeElementsWithVisibleFrame:")
            let imp = options.method(for: setSel)
            unsafeBitCast(imp, to: SetBoolFn.self)(options, setSel, true)
        }
        return options
    }

    // MARK: - Parser vs SPI Comparison (Both Configurations)

    func testParserMatchesSPI_tableView_top() {
        assertParserMatchesSPI(
            makeVC: { ScrollViewAccessibilityViewController(scrollPosition: .top) },
            label: "TableView top"
        )
    }

    func testParserMatchesSPI_tableView_middle() {
        assertParserMatchesSPI(
            makeVC: { ScrollViewAccessibilityViewController(scrollPosition: .middle) },
            label: "TableView middle"
        )
    }

    func testParserMatchesSPI_tableView_bottom() {
        assertParserMatchesSPI(
            makeVC: { ScrollViewAccessibilityViewController(scrollPosition: .bottom) },
            label: "TableView bottom"
        )
    }

    func testParserMatchesSPI_collectionView_top() {
        assertParserMatchesSPI(
            makeVC: { CollectionViewAccessibilityViewController(scrollPosition: .top) },
            label: "CollectionView top"
        )
    }

    func testParserMatchesSPI_collectionView_middle() {
        assertParserMatchesSPI(
            makeVC: { CollectionViewAccessibilityViewController(scrollPosition: .middle) },
            label: "CollectionView middle"
        )
    }

    func testParserMatchesSPI_collectionView_bottom() {
        assertParserMatchesSPI(
            makeVC: { CollectionViewAccessibilityViewController(scrollPosition: .bottom) },
            label: "CollectionView bottom"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_lazyVStack_top() {
        assertParserMatchesSPI(
            makeVC: { UIHostingController(rootView: SwiftUILazyScrollView(scrollPosition: .top)) },
            settleTime: 0.3,
            label: "LazyVStack top"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_lazyVStack_middle() {
        assertParserMatchesSPI(
            makeVC: { UIHostingController(rootView: SwiftUILazyScrollView(scrollPosition: .middle)) },
            settleTime: 0.3,
            label: "LazyVStack middle"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_lazyVStack_bottom() {
        assertParserMatchesSPI(
            makeVC: { UIHostingController(rootView: SwiftUILazyScrollView(scrollPosition: .bottom)) },
            settleTime: 0.3,
            label: "LazyVStack bottom"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_swiftUIList_top() {
        assertParserMatchesSPI(
            makeVC: { UIHostingController(rootView: SwiftUIScrollView(scrollPosition: .top)) },
            settleTime: 0.3,
            label: "SwiftUI List top"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_swiftUIList_middle() {
        assertParserMatchesSPI(
            makeVC: { UIHostingController(rootView: SwiftUIScrollView(scrollPosition: .middle)) },
            settleTime: 0.3,
            label: "SwiftUI List middle"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_swiftUIList_bottom() {
        assertParserMatchesSPI(
            makeVC: { UIHostingController(rootView: SwiftUIScrollView(scrollPosition: .bottom)) },
            settleTime: 0.3,
            label: "SwiftUI List bottom"
        )
    }

    // MARK: - Comparison Helpers

    private struct ElementIdentity: Equatable, CustomStringConvertible {
        let label: String?
        let traits: UIAccessibilityTraits

        init(from obj: NSObject) {
            label = obj.accessibilityLabel
            traits = obj.accessibilityTraits
        }

        init(from element: AccessibilityElement) {
            label = element.label
            traits = UIAccessibilityTraits(rawValue: element.traits.rawValue)
        }

        var description: String {
            var parts: [String] = []
            if let label { parts.append("label=\"\(label)\"") }
            if !traits.isEmpty { parts.append("traits=\(traits.rawValue)") }
            return "(\(parts.joined(separator: ", ")))"
        }
    }

    private func assertParserMatchesSPI(
        makeVC: () -> UIViewController,
        settleTime: TimeInterval = 0.1,
        skipFullTree: Bool = false,
        label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else {
            XCTFail("SPI not available", file: file, line: line)
            return
        }

        let vc = makeVC()
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        window.rootViewController = vc
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(settleTime))

        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        guard let optionsClass else {
            XCTFail("UIAccessibilityElementTraversalOptions not available", file: file, line: line)
            window.isHidden = true
            return
        }

        // --- Configuration 1: visible-frame filtering (pruning on) ---
        // The parser now always produces the full tree; trimming off-screen elements is a delivery
        // transform. `onscreen()` is the analog of the SPI's `visibleFrameOnly` pruning.
        do {
            let spiResult = vc.view.perform(
                sel, with: Self.makeOptions(optionsClass, visibleFrameOnly: true)
            )?.takeUnretainedValue() as? [NSObject] ?? []
            let spiIdentities = spiResult.map { ElementIdentity(from: $0) }

            let parserIdentities = AccessibilityHierarchyParser()
                .parseAccessibilityHierarchy(in: vc.view)
                .onscreen()
                .flattenToElements()
                .map { ElementIdentity(from: $0) }

            print("\(label) [pruned] — SPI: \(spiIdentities.count), Parser: \(parserIdentities.count)")

            XCTAssertEqual(
                parserIdentities.count, spiIdentities.count,
                "\(label) [pruned] count mismatch — Parser: \(parserIdentities.count), SPI: \(spiIdentities.count)",
                file: file, line: line
            )
            for (i, (p, s)) in zip(parserIdentities, spiIdentities).enumerated() {
                XCTAssertEqual(p, s, "\(label) [pruned] element \(i) — Parser: \(p), SPI: \(s)", file: file, line: line)
            }
        }

        // --- Configuration 2: no visible-frame filtering (pruning off) ---
        // UITableView's SPI walker uses the index API to enumerate all rows via the data source,
        // while our parser only walks instantiated subviews. Skip for UITableView.
        if !skipFullTree {
            do {
                let spiResult = vc.view.perform(
                    sel, with: Self.makeOptions(optionsClass, visibleFrameOnly: false)
                )?.takeUnretainedValue() as? [NSObject] ?? []
                let spiIdentities = spiResult.map { ElementIdentity(from: $0) }

                let parserIdentities = AccessibilityHierarchyParser()
                    .parseAccessibilityHierarchy(in: vc.view)
                    .flattenToElements()
                    .map { ElementIdentity(from: $0) }

                print("\(label) [full] — SPI: \(spiIdentities.count), Parser: \(parserIdentities.count)")

                XCTAssertEqual(
                    parserIdentities.count, spiIdentities.count,
                    "\(label) [full] count mismatch — Parser: \(parserIdentities.count), SPI: \(spiIdentities.count)",
                    file: file, line: line
                )
                for (i, (p, s)) in zip(parserIdentities, spiIdentities).enumerated() {
                    XCTAssertEqual(p, s, "\(label) [full] element \(i) — Parser: \(p), SPI: \(s)", file: file, line: line)
                }
            }

            // --- Configuration 3: SPI with honoring groups (no visibleFrameOnly) ---
            let voGroupSel = NSSelectorFromString("defaultVoiceOverOptionsHonoringGroups")
            if optionsClass.responds(to: voGroupSel) {
                let voGroupOptions = (optionsClass as AnyObject).perform(voGroupSel)?.takeUnretainedValue()
                let spiResult = vc.view.perform(sel, with: voGroupOptions)?.takeUnretainedValue() as? [NSObject] ?? []
                let spiIdentities = spiResult.map { ElementIdentity(from: $0) }

                let parserIdentities = AccessibilityHierarchyParser()
                    .parseAccessibilityHierarchy(in: vc.view)
                    .flattenToElements()
                    .map { ElementIdentity(from: $0) }

                print("\(label) [grouped] — SPI: \(spiIdentities.count), Parser: \(parserIdentities.count)")

                XCTAssertEqual(
                    parserIdentities.count, spiIdentities.count,
                    "\(label) [grouped] count mismatch — Parser: \(parserIdentities.count), SPI: \(spiIdentities.count)",
                    file: file, line: line
                )
                for (i, (p, s)) in zip(parserIdentities, spiIdentities).enumerated() {
                    XCTAssertEqual(p, s, "\(label) [grouped] element \(i) — Parser: \(p), SPI: \(s)", file: file, line: line)
                }
            }
        }

        window.isHidden = true
    }

    func testDiagnostic_groupedSPIStructure() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else { return }

        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        guard let optionsClass else { return }

        let voGroupSel = NSSelectorFromString("defaultVoiceOverOptionsHonoringGroups")
        guard optionsClass.responds(to: voGroupSel) else {
            print("defaultVoiceOverOptionsHonoringGroups not available")
            return
        }

        var viewControllers: [(String, UIViewController, TimeInterval)] = [
            ("SemanticGroups", Self.makeSemanticGroupVC(), 0.1),
        ]
        if #available(iOS 15.0, *) {
            viewControllers.append(("LazyVStack", UIHostingController(rootView: SwiftUILazyScrollView(scrollPosition: .top)), 0.3))
        }

        for (name, vc, settle) in viewControllers {
            vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
            window.rootViewController = vc
            window.makeKeyAndVisible()
            window.layoutIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(settle))

            let voGroupOptions = (optionsClass as AnyObject).perform(voGroupSel)?.takeUnretainedValue()
            let grouped = vc.view.perform(sel, with: voGroupOptions)?.takeUnretainedValue() as? [NSObject] ?? []
            let pruned = vc.view.perform(sel, with: Self.makeOptions(optionsClass, visibleFrameOnly: true))?.takeUnretainedValue() as? [NSObject] ?? []
            let full = vc.view.perform(sel, with: Self.makeOptions(optionsClass, visibleFrameOnly: false))?.takeUnretainedValue() as? [NSObject] ?? []

            print("\n===== \(name) =====")
            print("  Grouped: \(grouped.count)  Pruned: \(pruned.count)  Full: \(full.count)")

            print("\n  --- GROUPED (with container chain) ---")
            for (i, obj) in grouped.enumerated() {
                let cls = "\(type(of: obj))"
                let label = obj.accessibilityLabel ?? "(nil)"
                let traits = obj.accessibilityTraits.rawValue
                let frame = obj.accessibilityFrame
                let cType = obj.accessibilityContainerType.rawValue
                let frameStr = frame.width == 0 && frame.height == 0 ? "ZERO" : "\(Int(frame.minX)),\(Int(frame.minY)) \(Int(frame.width))x\(Int(frame.height))"
                print("  [\(i)] \(cls) label=\"\(label)\" traits=\(traits) frame=\(frameStr) cType=\(cType)")

                // Walk the full container chain
                var current: AnyObject? = obj
                var depth = 0
                while let c = (current as? NSObject)?.perform(NSSelectorFromString("accessibilityContainer"))?.takeUnretainedValue() {
                    depth += 1
                    let cObj = c as! NSObject
                    let cCls = "\(type(of: cObj))"
                    let cLabel = cObj.accessibilityLabel ?? "(nil)"
                    let cCType = cObj.accessibilityContainerType.rawValue
                    let cIsElem = cObj.isAccessibilityElement
                    let cGrouped = (cObj as? UIView)?.shouldGroupAccessibilityChildren ?? false
                    let cFrame = cObj.accessibilityFrame
                    let cFrameStr = cFrame.width == 0 && cFrame.height == 0 ? "ZERO" : "\(Int(cFrame.minX)),\(Int(cFrame.minY)) \(Int(cFrame.width))x\(Int(cFrame.height))"
                    let indent = String(repeating: "  ", count: depth)
                    print("       \(indent)↑ \(cCls) label=\"\(cLabel)\" cType=\(cCType) isElem=\(cIsElem) grouped=\(cGrouped) frame=\(cFrameStr)")
                    current = c
                    if depth > 10 { print("       \(indent)  (truncated)"); break }
                }
            }

            print("\n  --- PRUNED ---")
            for (i, obj) in pruned.enumerated() {
                let label = obj.accessibilityLabel ?? "(nil)"
                let traits = obj.accessibilityTraits.rawValue
                print("  [\(i)] \(type(of: obj)) label=\"\(label)\" traits=\(traits)")

                var current: AnyObject? = obj
                var depth = 0
                while let c = (current as? NSObject)?.perform(NSSelectorFromString("accessibilityContainer"))?.takeUnretainedValue() {
                    depth += 1
                    let cObj = c as! NSObject
                    let cCls = "\(type(of: cObj))"
                    let cLabel = cObj.accessibilityLabel ?? "(nil)"
                    let cCType = cObj.accessibilityContainerType.rawValue
                    let indent = String(repeating: "  ", count: depth)
                    print("       \(indent)↑ \(cCls) label=\"\(cLabel)\" cType=\(cCType)")
                    current = c
                    if depth > 10 { print("       \(indent)  (truncated)"); break }
                }
            }

            window.isHidden = true
        }
    }

    /// Introspects UIAccessibilityElementTraversalOptions to find every option axis,
    /// then diffs the three known factory configurations against each other.
    func testDiagnostic_traversalOptionsIntrospection() {
        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        guard let optionsClass else { return }

        print("=== INSTANCE METHODS ===")
        var count: UInt32 = 0
        if let methods = class_copyMethodList(optionsClass, &count) {
            for i in 0 ..< Int(count) {
                let selName = NSStringFromSelector(method_getName(methods[i]))
                let enc = method_getTypeEncoding(methods[i]).map { String(cString: $0) } ?? "?"
                print("  \(selName)  [\(enc)]")
            }
            free(methods)
        }

        print("\n=== CLASS METHODS ===")
        if let meta = object_getClass(optionsClass) {
            var classCount: UInt32 = 0
            if let methods = class_copyMethodList(meta, &classCount) {
                for i in 0 ..< Int(classCount) {
                    print("  +\(NSStringFromSelector(method_getName(methods[i])))")
                }
                free(methods)
            }
        }

        // Build the three configurations we know about and diff every BOOL getter.
        func makeInstance(_ factory: String?) -> NSObject? {
            if let factory {
                let sel = NSSelectorFromString(factory)
                guard optionsClass.responds(to: sel) else { return nil }
                return (optionsClass as AnyObject).perform(sel)?.takeUnretainedValue() as? NSObject
            }
            return (optionsClass as! NSObject.Type)
                .perform(NSSelectorFromString("alloc"))!.takeUnretainedValue()
                .perform(NSSelectorFromString("init"))!.takeUnretainedValue() as? NSObject
        }

        let instances: [(String, NSObject)] = [
            ("plainInit", makeInstance(nil)),
            ("defaultVoiceOverOptions", makeInstance("defaultVoiceOverOptions")),
            ("voHonoringGroups", makeInstance("defaultVoiceOverOptionsHonoringGroups")),
            ("defaultSwitchControlOptions", makeInstance("defaultSwitchControlOptions")),
        ].compactMap { name, obj in obj.map { (name, $0) } }

        typealias BoolGetter = @convention(c) (AnyObject, Selector) -> Bool
        var boolGetters: [String] = []
        var getterCount: UInt32 = 0
        if let methods = class_copyMethodList(optionsClass, &getterCount) {
            for i in 0 ..< Int(getterCount) {
                let m = methods[i]
                let selName = NSStringFromSelector(method_getName(m))
                let enc = method_getTypeEncoding(m).map { String(cString: $0) } ?? ""
                // BOOL getter with no arguments: encoding like "B16@0:8"
                if enc.hasPrefix("B"), method_getNumberOfArguments(m) == 2, !selName.hasPrefix("set") {
                    boolGetters.append(selName)
                }
            }
            free(methods)
        }
        boolGetters.sort()

        print("\n=== BOOL GETTER VALUES ===")
        let header = "getter".padding(toLength: 52, withPad: " ", startingAt: 0)
            + instances.map { $0.0.padding(toLength: 30, withPad: " ", startingAt: 0) }.joined()
        print(header)
        for getter in boolGetters {
            var row = getter.padding(toLength: 52, withPad: " ", startingAt: 0)
            for (_, instance) in instances {
                let sel = NSSelectorFromString(getter)
                guard let m = class_getInstanceMethod(type(of: instance), sel) else {
                    row += "n/a".padding(toLength: 30, withPad: " ", startingAt: 0)
                    continue
                }
                let value = unsafeBitCast(method_getImplementation(m), to: BoolGetter.self)(instance, sel)
                row += "\(value)".padding(toLength: 30, withPad: " ", startingAt: 0)
            }
            print(row)
        }
    }

    /// Maps exactly which container configurations the grouped walker collapses.
    /// One container + two labeled children per trial; vary the container's
    /// grouping flag, container type, label, element-ness, and class.
    func testDiagnostic_groupCollapseMatrix() {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard UIView().responds(to: sel) else { return }
        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        guard let optionsClass else { return }
        let voGroupSel = NSSelectorFromString("defaultVoiceOverOptionsHonoringGroups")
        guard optionsClass.responds(to: voGroupSel) else { return }

        struct Trial {
            let name: String
            let make: () -> (root: UIView, container: UIView)
        }

        func standardChildren(in container: UIView) {
            let c1 = UILabel(frame: CGRect(x: 10, y: 5, width: 100, height: 30))
            c1.text = "A"
            c1.isAccessibilityElement = true
            let c2 = UILabel(frame: CGRect(x: 10, y: 40, width: 100, height: 30))
            c2.text = "B"
            c2.isAccessibilityElement = true
            container.addSubview(c1)
            container.addSubview(c2)
        }

        func makeTrial(
            name: String,
            grouped: Bool,
            cType: UIAccessibilityContainerType,
            label: String?,
            isElement: Bool = false,
            containerClass: UIView.Type = UIView.self,
            customize: ((UIView) -> Void)? = nil
        ) -> Trial {
            Trial(name: name) {
                let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
                let container = containerClass.init(frame: CGRect(x: 0, y: 50, width: 375, height: 80))
                container.shouldGroupAccessibilityChildren = grouped
                container.accessibilityContainerType = cType
                container.accessibilityLabel = label
                container.isAccessibilityElement = isElement
                standardChildren(in: container)
                customize?(container)
                root.addSubview(container)
                return (root, container)
            }
        }

        var trials: [Trial] = []

        // Full matrix: grouped × containerType × label
        let cTypes: [(String, UIAccessibilityContainerType)] = [
            ("none", .none),
            ("dataTable", .dataTable),
            ("list", .list),
            ("landmark", .landmark),
            ("semanticGroup", .semanticGroup),
        ]
        for grouped in [false, true] {
            for (ctName, ct) in cTypes {
                for label in [nil, "L"] as [String?] {
                    trials.append(makeTrial(
                        name: "grouped=\(grouped ? "Y" : "n") cType=\(ctName.padding(toLength: 13, withPad: " ", startingAt: 0)) label=\(label ?? "nil")",
                        grouped: grouped, cType: ct, label: label
                    ))
                }
            }
        }

        // Edge cases
        trials.append(makeTrial(
            name: "container isElement=true (label=L)",
            grouped: false, cType: .none, label: "L", isElement: true
        ))
        trials.append(makeTrial(
            name: "UIStackView grouped=Y cType=none",
            grouped: true, cType: .none, label: nil, containerClass: UIStackView.self
        ))
        trials.append(makeTrial(
            name: "grouped=Y semanticGroup + explicit a11yElements",
            grouped: true, cType: .semanticGroup, label: "L",
            customize: { container in
                container.accessibilityElements = container.subviews
            }
        ))
        trials.append(makeTrial(
            name: "grouped=Y semanticGroup + a11yValue only",
            grouped: true, cType: .semanticGroup, label: nil,
            customize: { $0.accessibilityValue = "V" }
        ))
        trials.append(Trial(name: "grouped=Y semanticGroup, 0 accessible children") {
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
            let container = UIView(frame: CGRect(x: 0, y: 50, width: 375, height: 80))
            container.shouldGroupAccessibilityChildren = true
            container.accessibilityContainerType = .semanticGroup
            container.accessibilityLabel = "L"
            root.addSubview(container)
            return (root, container)
        })
        trials.append(Trial(name: "grouped=Y semanticGroup, grandchildren only") {
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
            let container = UIView(frame: CGRect(x: 0, y: 50, width: 375, height: 80))
            container.shouldGroupAccessibilityChildren = true
            container.accessibilityContainerType = .semanticGroup
            let middle = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 80))
            standardChildren(in: middle)
            container.addSubview(middle)
            root.addSubview(container)
            return (root, container)
        })
        trials.append(Trial(name: "nested grouped: outer semanticGroup > inner semanticGroup") {
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
            let outer = UIView(frame: CGRect(x: 0, y: 50, width: 375, height: 80))
            outer.shouldGroupAccessibilityChildren = true
            outer.accessibilityContainerType = .semanticGroup
            outer.accessibilityLabel = "Outer"
            let inner = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 40))
            inner.shouldGroupAccessibilityChildren = true
            inner.accessibilityContainerType = .semanticGroup
            inner.accessibilityLabel = "Inner"
            standardChildren(in: inner)
            outer.addSubview(inner)
            root.addSubview(outer)
            return (root, outer)
        })
        trials.append(Trial(name: "grouped=n outer > grouped=Y inner semanticGroup") {
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
            let outer = UIView(frame: CGRect(x: 0, y: 50, width: 375, height: 80))
            let inner = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 40))
            inner.shouldGroupAccessibilityChildren = true
            inner.accessibilityContainerType = .semanticGroup
            inner.accessibilityLabel = "Inner"
            standardChildren(in: inner)
            outer.addSubview(inner)
            root.addSubview(outer)
            return (root, inner)
        })

        // Sweep raw containerType values beyond the public enum (HostingScrollView
        // reported cType=12), with and without a label.
        typealias SetIntFn = @convention(c) (AnyObject, Selector, Int) -> Void
        let setCTypeSel = NSSelectorFromString("setAccessibilityContainerType:")
        for rawType in 0 ... 15 {
            for label in [nil, "L"] as [String?] {
                trials.append(Trial(name: "rawCType=\(String(rawType).padding(toLength: 2, withPad: " ", startingAt: 0)) label=\(label ?? "nil")") {
                    let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
                    let container = UIView(frame: CGRect(x: 0, y: 50, width: 375, height: 80))
                    let imp = container.method(for: setCTypeSel)
                    unsafeBitCast(imp, to: SetIntFn.self)(container, setCTypeSel, rawType)
                    container.accessibilityLabel = label
                    standardChildren(in: container)
                    root.addSubview(container)
                    return (root, container)
                })
            }
        }

        // Which semanticGroup properties qualify it for collapse?
        for (propName, customize) in [
            ("identifier", { (v: UIView) in v.accessibilityIdentifier = "id" }),
            ("hint", { (v: UIView) in v.accessibilityHint = "hint" }),
            ("attributedLabel", { (v: UIView) in v.accessibilityAttributedLabel = NSAttributedString(string: "AL") }),
            ("userInputLabels", { (v: UIView) in v.accessibilityUserInputLabels = ["UIL"] }),
        ] as [(String, (UIView) -> Void)] {
            trials.append(makeTrial(
                name: "semanticGroup + \(propName) only",
                grouped: false, cType: .semanticGroup, label: nil,
                customize: customize
            ))
        }

        print("=== GROUP COLLAPSE MATRIX (grouped SPI vs pruned SPI) ===")
        for trial in trials {
            let (root, container) = trial.make()
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
            window.addSubview(root)
            window.makeKeyAndVisible()
            window.layoutIfNeeded()

            let voGroupOptions = (optionsClass as AnyObject).perform(voGroupSel)?.takeUnretainedValue()
            let grouped = root.perform(sel, with: voGroupOptions)?.takeUnretainedValue() as? [NSObject] ?? []
            let pruned = root.perform(sel, with: Self.makeOptions(optionsClass, visibleFrameOnly: true))?.takeUnretainedValue() as? [NSObject] ?? []

            func describe(_ result: [NSObject]) -> String {
                if result.isEmpty { return "EMPTY" }
                let parts = result.map { obj -> String in
                    if obj === container { return "«CONTAINER»" }
                    return obj.accessibilityLabel ?? "(\(type(of: obj)))"
                }
                return parts.joined(separator: ", ")
            }

            let verdict: String
            if grouped.count == 1, grouped[0] === container {
                verdict = "COLLAPSED"
            } else if grouped.contains(where: { $0 === container }) {
                verdict = "MIXED"
            } else if grouped.isEmpty {
                verdict = "EMPTY"
            } else {
                verdict = "DRILLED"
            }

            print("\(trial.name.padding(toLength: 56, withPad: " ", startingAt: 0)) → \(verdict.padding(toLength: 10, withPad: " ", startingAt: 0)) grouped=[\(describe(grouped))] pruned=[\(describe(pruned))]")

            window.isHidden = true
        }
    }

    /// Demonstrates where walk-path context derivation loses list/landmark context that the
    /// element's own `accessibilityContainer` chain still carries.
    func testDiagnostic_contextGapViaContainerChain() {
        let containerSel = NSSelectorFromString("accessibilityContainer")
        print("bare NSObject responds to accessibilityContainer: \(NSObject().responds(to: containerSel))")
        print("bare NSObject accessibilityContainer value: \(String(describing: NSObject().perform(containerSel)?.takeUnretainedValue()))")

        func makeListFixture(explicitArray: Bool) -> UIView {
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
            let list = UIView(frame: CGRect(x: 0, y: 50, width: 375, height: 80))
            list.accessibilityContainerType = .list
            let l1 = UILabel(frame: CGRect(x: 10, y: 5, width: 100, height: 30))
            l1.text = "First"
            l1.isAccessibilityElement = true
            let l2 = UILabel(frame: CGRect(x: 10, y: 40, width: 100, height: 30))
            l2.text = "Last"
            l2.isAccessibilityElement = true
            list.addSubview(l1)
            list.addSubview(l2)
            if explicitArray {
                list.accessibilityElements = [l1, l2]
            }
            root.addSubview(list)
            return root
        }

        let fixtures: [(String, UIView, UIViewController?)] = {
            let tableVC = ScrollViewAccessibilityViewController(scrollPosition: .top)
            return [
                ("list via explicit a11yElements array", makeListFixture(explicitArray: true), nil),
                ("list via plain subviews", makeListFixture(explicitArray: false), nil),
                ("UITableView", tableVC.view, tableVC),
            ]
        }()

        for (name, rootView, vc) in fixtures {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
            if let vc {
                vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
                window.rootViewController = vc
            } else {
                window.addSubview(rootView)
            }
            window.makeKeyAndVisible()
            window.layoutIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))

            print("\n===== \(name) =====")

            // What the parser says (descriptions carry "List Start."/"List End.")
            let elements = AccessibilityHierarchyParser()
                .parseAccessibilityHierarchy(in: vc?.view ?? rootView)
                .flattenToElements()
            print("  PARSER:")
            for e in elements.prefix(4) {
                print("    \"\(e.description)\"")
            }
            if elements.count > 4 { print("    … (\(elements.count - 4) more)") }
            if let last = elements.last, elements.count > 4 {
                print("    last: \"\(last.description)\"")
            }

            // What the element's own container chain says
            let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
            let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
            guard let optionsClass else { continue }
            let leaves = (vc?.view ?? rootView).perform(
                sel, with: Self.makeOptions(optionsClass, visibleFrameOnly: true)
            )?.takeUnretainedValue() as? [NSObject] ?? []

            print("  CHAIN (per SPI leaf):")
            for leaf in [leaves.first, leaves.last].compactMap({ $0 }) {
                var child: NSObject = leaf
                var chainDesc = "    \"\(leaf.accessibilityLabel ?? "?")\""
                var depth = 0
                while depth < 15 {
                    depth += 1
                    guard child.responds(to: containerSel),
                          let parent = child.perform(containerSel)?.takeUnretainedValue() as? NSObject
                    else { break }
                    let cType = parent.accessibilityContainerType
                    if cType != .none {
                        let index = parent.index(ofAccessibilityElement: child)
                        let count = parent.accessibilityElementCount()
                        chainDesc += " → ancestor \(type(of: parent)) cType=\(cType.rawValue), index(directChild)=\(index == NSNotFound ? "NSNotFound" : "\(index)"), count=\(count == NSNotFound ? "NSNotFound" : "\(count)")"
                        break
                    }
                    child = parent
                }
                if depth >= 15 || !chainDesc.contains("ancestor") {
                    chainDesc += " → no typed ancestor found"
                }
                print(chainDesc)
            }

            window.isHidden = true
        }
    }

    func testRealUIKitViewsIndexAPIBehavior() {
        let views: [(String, UIView)] = [
            ("UITableView", UITableView()),
            ("UICollectionView", UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())),
            ("UIScrollView", UIScrollView()),
            ("UISegmentedControl", UISegmentedControl(items: ["A", "B"])),
            ("UIStackView", UIStackView()),
            ("UITabBar", UITabBar()),
            ("UIToolbar", UIToolbar()),
            ("UINavigationBar", UINavigationBar()),
            ("UISearchBar", UISearchBar()),
        ]

        for (name, view) in views {
            let count = view.accessibilityElementCount()
            let hasElements = view.accessibilityElements != nil
            let usesIndexAPIOnly = count != NSNotFound && count > 0 && !hasElements
            print("\(name): count=\(count == NSNotFound ? "NSNotFound" : "\(count)"), accessibilityElements=\(hasElements ? "set" : "nil"), indexAPIOnly=\(usesIndexAPIOnly)")
        }
    }
}

// MARK: - Test Fixtures

/// A UIView that implements the index-based container APIs.
/// Our claim: Apple's walker ignores these and walks subviews instead.
private final class IndexAPIUIView: UIView {
    private lazy var phantomElement: UIAccessibilityElement = {
        let element = UIAccessibilityElement(accessibilityContainer: self)
        element.accessibilityLabel = "Phantom Element"
        element.accessibilityFrame = CGRect(x: 0, y: 50, width: 200, height: 40)
        return element
    }()

    override func accessibilityElementCount() -> Int { 1 }
    override func accessibilityElement(at index: Int) -> Any? { index == 0 ? phantomElement : nil }
}

/// A non-UIView NSObject that implements the index-based container APIs.
/// Our claim: Apple's walker DOES use the index API for these.
private final class IndexAPINSObject: NSObject {
    private let elements: [NSObject]
    private let count: Int

    init(elements: [NSObject], reportedCount: Int? = nil) {
        self.elements = elements
        count = reportedCount ?? elements.count
    }

    override func accessibilityElementCount() -> Int { count }
    override func accessibilityElement(at index: Int) -> Any? {
        index < elements.count ? elements[index] : nil
    }
}

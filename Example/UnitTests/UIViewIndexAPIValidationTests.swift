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

    // MARK: - Helpers

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

    // MARK: - Parser vs SPI Comparison

    func testParserMatchesSPI_tableView_top() {
        assertParserMatchesSPIVisibleFrame(
            makeVC: { ScrollViewAccessibilityViewController(scrollPosition: .top) },
            label: "TableView top"
        )
    }

    func testParserMatchesSPI_tableView_middle() {
        assertParserMatchesSPIVisibleFrame(
            makeVC: { ScrollViewAccessibilityViewController(scrollPosition: .middle) },
            label: "TableView middle"
        )
    }

    func testParserMatchesSPI_tableView_bottom() {
        assertParserMatchesSPIVisibleFrame(
            makeVC: { ScrollViewAccessibilityViewController(scrollPosition: .bottom) },
            label: "TableView bottom"
        )
    }

    func testParserMatchesSPI_collectionView_top() {
        assertParserMatchesSPIVisibleFrame(
            makeVC: { CollectionViewAccessibilityViewController(scrollPosition: .top) },
            label: "CollectionView top"
        )
    }

    func testParserMatchesSPI_collectionView_middle() {
        assertParserMatchesSPIVisibleFrame(
            makeVC: { CollectionViewAccessibilityViewController(scrollPosition: .middle) },
            label: "CollectionView middle"
        )
    }

    func testParserMatchesSPI_collectionView_bottom() {
        assertParserMatchesSPIVisibleFrame(
            makeVC: { CollectionViewAccessibilityViewController(scrollPosition: .bottom) },
            label: "CollectionView bottom"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_lazyVStack_top() {
        assertParserMatchesSPIVisibleFrame(
            makeHosted: { SwiftUILazyScrollView(scrollPosition: .top) },
            settleTime: 0.3,
            label: "LazyVStack top"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_lazyVStack_middle() {
        assertParserMatchesSPIVisibleFrame(
            makeHosted: { SwiftUILazyScrollView(scrollPosition: .middle) },
            settleTime: 0.3,
            label: "LazyVStack middle"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_lazyVStack_bottom() {
        assertParserMatchesSPIVisibleFrame(
            makeHosted: { SwiftUILazyScrollView(scrollPosition: .bottom) },
            settleTime: 0.3,
            label: "LazyVStack bottom"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_swiftUIList_top() {
        assertParserMatchesSPIVisibleFrame(
            makeHosted: { SwiftUIScrollView(scrollPosition: .top) },
            settleTime: 0.3,
            label: "SwiftUI List top"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_swiftUIList_middle() {
        assertParserMatchesSPIVisibleFrame(
            makeHosted: { SwiftUIScrollView(scrollPosition: .middle) },
            settleTime: 0.3,
            label: "SwiftUI List middle"
        )
    }

    @available(iOS 15.0, *)
    func testParserMatchesSPI_swiftUIList_bottom() {
        assertParserMatchesSPIVisibleFrame(
            makeHosted: { SwiftUIScrollView(scrollPosition: .bottom) },
            settleTime: 0.3,
            label: "SwiftUI List bottom"
        )
    }

    private func assertParserMatchesSPIVisibleFrame(
        makeVC: () -> UIViewController,
        settleTime: TimeInterval = 0.1,
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

        let options = Self.makeOptions(optionsClass, visibleFrameOnly: true)
        let spiResult = vc.view.perform(sel, with: options)?.takeUnretainedValue() as? [NSObject] ?? []
        let spiLabels = spiResult.compactMap { $0.accessibilityLabel }.sorted()

        let parser = AccessibilityHierarchyParser()
        let parserElements = parser.parseAccessibilityHierarchy(in: vc.view).flattenToElements()
        let parserLabels = parserElements.compactMap { $0.label }.sorted()

        print("\(label) — SPI: \(spiLabels.count), Parser: \(parserLabels.count)")

        XCTAssertEqual(
            parserLabels.count,
            spiLabels.count,
            "\(label) count mismatch — Parser: \(parserLabels.count) [\(parserLabels)], SPI: \(spiLabels.count) [\(spiLabels)]",
            file: file,
            line: line
        )
        XCTAssertEqual(
            parserLabels,
            spiLabels,
            "\(label) label mismatch — Parser: \(parserLabels), SPI: \(spiLabels)",
            file: file,
            line: line
        )

        window.isHidden = true
    }

    @available(iOS 15.0, *)
    private func assertParserMatchesSPIVisibleFrame<V: View>(
        makeHosted: () -> V,
        settleTime: TimeInterval = 0.1,
        label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertParserMatchesSPIVisibleFrame(
            makeVC: {
                let host = UIHostingController(rootView: makeHosted())
                return host
            },
            settleTime: settleTime,
            label: label,
            file: file,
            line: line
        )
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

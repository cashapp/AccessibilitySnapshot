import SwiftUI
import UIKit
import XCTest
@testable import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotParser

/// Compares the parser's output against `_accessibilityLeafDescendantsWithOptions:` for every
/// snapshot test view. Each divergence is a potential parser bug or an intentional difference
/// that should be documented.
final class SPIComparisonHarness: XCTestCase {

    private static var report: [String] = []

    override class func setUp() {
        super.setUp()
        report = []
    }

    override class func tearDown() {
        let outputPath = NSTemporaryDirectory() + "spi-comparison-report.txt"
        let content = report.joined(separator: "\n")
        try? content.write(toFile: outputPath, atomically: true, encoding: .utf8)
        NSLog("[SPI] Report written to \(outputPath)")
        NSLog("[SPI] Summary: \(report.filter { $0.hasPrefix("✅") }.count) matches, \(report.filter { $0.hasPrefix("❌") }.count) divergences")
        super.tearDown()
    }

    // MARK: - Helpers

    private func compare(view: UIView, name: String, file: StaticString = #file, line: UInt = #line) {
        let window = UIWindow(frame: view.frame)
        window.addSubview(view)
        window.makeKeyAndVisible()
        view.layoutIfNeeded()

        defer {
            window.isHidden = true
            view.removeFromSuperview()
        }

        let parser = AccessibilityHierarchyParser()
        let parserElements = parser.parseAccessibilityHierarchy(in: view).flattenToElements()
        let spiElements = spiLeafDescendants(in: view)

        let parserLabels = parserElements.compactMap { $0.label }
        let spiLabels = spiElements.compactMap { $0.accessibilityLabel }

        if parserLabels == spiLabels {
            Self.report.append("✅ \(name) — \(parserLabels.count) elements match")
        } else {
            var lines: [String] = []
            lines.append("❌ \(name)")
            lines.append("  Parser (\(parserLabels.count)): \(parserLabels.joined(separator: " | "))")
            lines.append("  SPI    (\(spiLabels.count)): \(spiLabels.joined(separator: " | "))")

            let parserSet = Set(parserLabels)
            let spiSet = Set(spiLabels)
            let onlyParser = parserSet.subtracting(spiSet).sorted()
            let onlySPI = spiSet.subtracting(parserSet).sorted()
            if !onlyParser.isEmpty { lines.append("  Only parser: \(onlyParser.joined(separator: " | "))") }
            if !onlySPI.isEmpty { lines.append("  Only SPI:    \(onlySPI.joined(separator: " | "))") }

            // Order diff
            let commonLabels = parserLabels.filter { spiSet.contains($0) }
            let spiCommonLabels = spiLabels.filter { parserSet.contains($0) }
            if commonLabels != spiCommonLabels && !commonLabels.isEmpty {
                lines.append("  Order differs for shared elements")
            }

            for line in lines { Self.report.append(line) }
        }
    }

    private func spiLeafDescendants(in view: UIView) -> [NSObject] {
        let sel = NSSelectorFromString("_accessibilityLeafDescendantsWithOptions:")
        guard view.responds(to: sel) else { return [] }

        let optionsClass: AnyClass? = NSClassFromString("UIAccessibilityElementTraversalOptions")
        guard let options = (optionsClass as? NSObject.Type)?.init() else { return [] }

        if options.responds(to: NSSelectorFromString("setSorted:")) {
            options.setValue(true, forKey: "sorted")
        }

        guard let raw = view.perform(sel, with: options)?.takeUnretainedValue() as? [NSObject]
        else { return [] }
        return raw
    }

    // MARK: - Tests

    func testSimpleLabels() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 200))
        let label = UIView(frame: CGRect(x: 10, y: 10, width: 200, height: 44))
        label.isAccessibilityElement = true
        label.accessibilityLabel = "Hello"
        root.addSubview(label)

        let button = UIView(frame: CGRect(x: 10, y: 60, width: 200, height: 44))
        button.isAccessibilityElement = true
        button.accessibilityLabel = "Tap"
        button.accessibilityTraits = .button
        root.addSubview(button)

        compare(view: root, name: "Simple labels")
    }

    func testGroupedElements() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 300))

        let group = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 200))
        group.shouldGroupAccessibilityChildren = true
        root.addSubview(group)

        for i in 0..<4 {
            let item = UIView(frame: CGRect(x: 10, y: i * 50, width: 355, height: 44))
            item.isAccessibilityElement = true
            item.accessibilityLabel = "Group Item \(i)"
            group.addSubview(item)
        }

        let outside = UIView(frame: CGRect(x: 10, y: 210, width: 200, height: 44))
        outside.isAccessibilityElement = true
        outside.accessibilityLabel = "Outside"
        root.addSubview(outside)

        compare(view: root, name: "Grouped elements")
    }

    func testTableView() {
        let root = TableViewHelper(frame: CGRect(x: 0, y: 0, width: 375, height: 400), rowCount: 30)
        compare(view: root, name: "UITableView (30 rows)")
    }

    func testSegmentedControl() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 100))
        let seg = UISegmentedControl(items: ["One", "Two", "Three"])
        seg.frame = CGRect(x: 10, y: 10, width: 355, height: 44)
        seg.selectedSegmentIndex = 0
        root.addSubview(seg)
        compare(view: root, name: "UISegmentedControl")
    }

    func testSwitch() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 100))
        let toggle = UISwitch(frame: CGRect(x: 10, y: 10, width: 51, height: 31))
        toggle.isOn = true
        toggle.accessibilityLabel = "Dark Mode"
        root.addSubview(toggle)
        compare(view: root, name: "UISwitch")
    }

    func testTextField() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 100))
        let field = UITextField(frame: CGRect(x: 10, y: 10, width: 355, height: 44))
        field.placeholder = "Enter text"
        field.accessibilityLabel = "Name"
        root.addSubview(field)
        compare(view: root, name: "UITextField")
    }

    func testModalView() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))

        let bg = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 44))
        bg.isAccessibilityElement = true
        bg.accessibilityLabel = "Background"
        root.addSubview(bg)

        let modal = UIView(frame: CGRect(x: 0, y: 100, width: 375, height: 200))
        modal.accessibilityViewIsModal = true
        root.addSubview(modal)

        let modalChild = UIView(frame: CGRect(x: 10, y: 10, width: 200, height: 44))
        modalChild.isAccessibilityElement = true
        modalChild.accessibilityLabel = "Modal Content"
        modal.addSubview(modalChild)

        compare(view: root, name: "Modal view")
    }

    func testHiddenElements() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 200))

        let visible = UIView(frame: CGRect(x: 10, y: 10, width: 200, height: 44))
        visible.isAccessibilityElement = true
        visible.accessibilityLabel = "Visible"
        root.addSubview(visible)

        let hidden = UIView(frame: CGRect(x: 10, y: 60, width: 200, height: 44))
        hidden.isAccessibilityElement = true
        hidden.accessibilityLabel = "Hidden"
        hidden.isHidden = true
        root.addSubview(hidden)

        let alpha0 = UIView(frame: CGRect(x: 10, y: 110, width: 200, height: 44))
        alpha0.isAccessibilityElement = true
        alpha0.accessibilityLabel = "Zero Alpha"
        alpha0.alpha = 0
        root.addSubview(alpha0)

        compare(view: root, name: "Hidden/alpha elements")
    }

    func testNestedContainers() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))

        let list = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 200))
        list.accessibilityContainerType = .list
        root.addSubview(list)

        for i in 0..<3 {
            let item = UIView(frame: CGRect(x: 10, y: i * 60, width: 355, height: 50))
            item.isAccessibilityElement = true
            item.accessibilityLabel = "List Item \(i)"
            list.addSubview(item)
        }

        let landmark = UIView(frame: CGRect(x: 0, y: 200, width: 375, height: 200))
        landmark.accessibilityContainerType = .landmark
        root.addSubview(landmark)

        let landmarkItem = UIView(frame: CGRect(x: 10, y: 10, width: 355, height: 50))
        landmarkItem.isAccessibilityElement = true
        landmarkItem.accessibilityLabel = "Landmark Item"
        landmark.addSubview(landmarkItem)

        compare(view: root, name: "Nested containers (list + landmark)")
    }

    func testCustomActions() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 100))
        let item = UIView(frame: CGRect(x: 10, y: 10, width: 355, height: 44))
        item.isAccessibilityElement = true
        item.accessibilityLabel = "Message"
        item.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Delete", target: nil, selector: #selector(NSObject.accessibilityActivate)),
            UIAccessibilityCustomAction(name: "Archive", target: nil, selector: #selector(NSObject.accessibilityActivate)),
        ]
        root.addSubview(item)
        compare(view: root, name: "Custom actions")
    }

    func testZeroFrameWrapper() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 200))

        let wrapper = UIView(frame: .zero)
        wrapper.clipsToBounds = false
        root.addSubview(wrapper)

        let child = UIView(frame: CGRect(x: 10, y: 10, width: 200, height: 44))
        child.isAccessibilityElement = true
        child.accessibilityLabel = "Inside wrapper"
        wrapper.addSubview(child)

        compare(view: root, name: "Zero-frame non-clipping wrapper")
    }

    @available(iOS 16.0, *)
    func testSwiftUISearchable() {
        let view = SwiftUISearchableView()
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)

        let window = UIWindow(frame: host.view.frame)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        compare(view: host.view, name: "SwiftUI .searchable()")

        window.isHidden = true
        window.rootViewController = nil
    }
}

// MARK: - Helpers

private final class TableViewHelper: UIView, UITableViewDataSource {
    private let tableView: UITableView
    private let rowCount: Int

    init(frame: CGRect, rowCount: Int) {
        self.rowCount = rowCount
        self.tableView = UITableView(frame: CGRect(origin: .zero, size: frame.size), style: .plain)
        super.init(frame: frame)
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        addSubview(tableView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rowCount }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        cell.accessibilityLabel = "Row \(indexPath.row)"
        return cell
    }
}

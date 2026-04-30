import SwiftUI
import UIKit

// MARK: - SwiftUI Modifiers

extension View {
    /// Wraps the content in a UIKit view that reports the given `UIAccessibilityContainerType`.
    /// SwiftUI has no native equivalent for container types, so we need a `UIViewRepresentable`.
    func accessibilityContainer(
        type: UIAccessibilityContainerType,
        label: String? = nil,
        value: String? = nil,
        identifier: String? = nil
    ) -> some View {
        ContainerTypeWrapper(
            kind: .containerType(type),
            label: label,
            value: value,
            identifier: identifier
        ) { self }
    }

    /// Wraps the content in a UIKit view with `accessibilityTraits = .tabBar`.
    func accessibilityTabBar() -> some View {
        ContainerTypeWrapper(kind: .tabBarTrait) { self }
    }
}

// MARK: - UIViewRepresentable

private struct ContainerTypeWrapper<Content: View>: UIViewRepresentable {
    enum Kind {
        case containerType(UIAccessibilityContainerType)
        case tabBarTrait
    }

    let kind: Kind
    var label: String? = nil
    var value: String? = nil
    var identifier: String? = nil
    let content: Content

    init(
        kind: Kind,
        label: String? = nil,
        value: String? = nil,
        identifier: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.kind = kind
        self.label = label
        self.value = value
        self.identifier = identifier
        self.content = content()
    }

    func makeUIView(context: Context) -> ContainerUIView {
        let container: ContainerUIView
        switch kind {
        case let .containerType(type):
            container = ContainerUIView(containerType: type)
        case .tabBarTrait:
            container = ContainerUIView(tabBarTrait: true)
        }
        applyAccessibility(to: container)

        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        context.coordinator.hostingController = hosting
        return container
    }

    func updateUIView(_ uiView: ContainerUIView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        applyAccessibility(to: uiView)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ContainerUIView, context: Context) -> CGSize? {
        guard let hosting = context.coordinator.hostingController else { return nil }
        let target = CGSize(
            width: proposal.width ?? UIView.layoutFittingCompressedSize.width,
            height: proposal.height ?? UIView.layoutFittingCompressedSize.height
        )
        return hosting.sizeThatFits(in: target)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var hostingController: UIHostingController<Content>?
    }

    private func applyAccessibility(to view: UIView) {
        view.accessibilityLabel = label
        view.accessibilityValue = value
        view.accessibilityIdentifier = identifier
    }
}

// MARK: - UIKit Container

/// A UIView that reports a configurable `UIAccessibilityContainerType` and optionally the `.tabBar` trait.
private class ContainerUIView: UIView {
    private let configuredContainerType: UIAccessibilityContainerType
    private let usesTabBarTrait: Bool

    init(containerType: UIAccessibilityContainerType) {
        configuredContainerType = containerType
        usesTabBarTrait = false
        super.init(frame: .zero)
        isAccessibilityElement = false
    }

    init(tabBarTrait: Bool) {
        configuredContainerType = .none
        usesTabBarTrait = tabBarTrait
        super.init(frame: .zero)
        isAccessibilityElement = false
    }

    override var accessibilityContainerType: UIAccessibilityContainerType {
        get { configuredContainerType }
        set {}
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get { usesTabBarTrait ? .tabBar : super.accessibilityTraits }
        set { super.accessibilityTraits = newValue }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Data Table

/// A SwiftUI wrapper that renders a 2D grid of text cells inside a proper
/// `UIAccessibilityContainerDataTable`. Each cell is a real `UIAccessibilityElement`
/// with correct row/column ranges, so VoiceOver (and the accessibility parser) can
/// navigate the table cell by cell.
struct AccessibilityDataTable: UIViewRepresentable {
    let cells: [[String]]

    private var rowCount: Int { cells.count }
    private var columnCount: Int { cells.first?.count ?? 0 }

    func makeUIView(context: Context) -> DataTableUIView {
        DataTableUIView(cells: cells)
    }

    func updateUIView(_ uiView: DataTableUIView, context: Context) {
        uiView.update(cells: cells)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: DataTableUIView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIView.layoutFittingCompressedSize.width
        return uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}

/// UIKit view that renders labels in a grid and exposes each cell as a
/// `UIAccessibilityContainerDataTableCell` with proper row/column indices.
final class DataTableUIView: UIView, UIAccessibilityContainerDataTable {
    private var cellElements: [[DataTableCell]] = []
    private var labelViews: [[UILabel]] = []

    init(cells: [[String]]) {
        super.init(frame: .zero)
        isAccessibilityElement = false
        rebuild(cells: cells)
    }

    func update(cells: [[String]]) {
        rebuild(cells: cells)
    }

    private func rebuild(cells: [[String]]) {
        // Tear down existing subviews so repeated updates don't stack.
        subviews.forEach { $0.removeFromSuperview() }
        labelViews = []
        cellElements = []

        let rowStack = UIStackView()
        rowStack.axis = .vertical
        rowStack.alignment = .leading
        rowStack.spacing = 4
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        for (r, row) in cells.enumerated() {
            let columnStack = UIStackView()
            columnStack.axis = .horizontal
            columnStack.alignment = .firstBaseline
            columnStack.spacing = 12

            var columnLabels: [UILabel] = []
            var columnCells: [DataTableCell] = []
            for (c, text) in row.enumerated() {
                let label = UILabel()
                label.text = text
                label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
                label.isAccessibilityElement = false
                columnStack.addArrangedSubview(label)
                columnLabels.append(label)

                let cell = DataTableCell(container: self, row: r, column: c, labelView: label)
                cell.accessibilityLabel = text
                columnCells.append(cell)
            }
            labelViews.append(columnLabels)
            cellElements.append(columnCells)
            rowStack.addArrangedSubview(columnStack)
        }

        addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: topAnchor),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    override var accessibilityContainerType: UIAccessibilityContainerType {
        get { .dataTable }
        set {}
    }

    override var accessibilityElements: [Any]? {
        get { cellElements.flatMap { $0 } }
        set {}
    }

    // MARK: UIAccessibilityContainerDataTable

    func accessibilityRowCount() -> Int { cellElements.count }
    func accessibilityColumnCount() -> Int { cellElements.first?.count ?? 0 }

    func accessibilityDataTableCellElement(forRow row: Int, column: Int) -> UIAccessibilityContainerDataTableCell? {
        guard cellElements.indices.contains(row),
              cellElements[row].indices.contains(column)
        else {
            return nil
        }
        return cellElements[row][column]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

/// A single cell inside an `AccessibilityDataTable`. Reads its on-screen frame directly
/// from the backing `UILabel` so callers always see the current layout, regardless of when
/// the container was last laid out.
private final class DataTableCell: UIAccessibilityElement, UIAccessibilityContainerDataTableCell {
    let row: Int
    let column: Int
    private weak var labelView: UILabel?

    init(container: Any, row: Int, column: Int, labelView: UILabel) {
        self.row = row
        self.column = column
        self.labelView = labelView
        super.init(accessibilityContainer: container)
    }

    override var accessibilityFrame: CGRect {
        get {
            guard let labelView, let window = labelView.window else {
                return super.accessibilityFrame
            }
            return labelView.convert(labelView.bounds, to: window)
        }
        set { super.accessibilityFrame = newValue }
    }

    func accessibilityRowRange() -> NSRange { NSRange(location: row, length: 1) }
    func accessibilityColumnRange() -> NSRange { NSRange(location: column, length: 1) }
}

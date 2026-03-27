import AccessibilitySnapshotPreviews
import SwiftUI
import UIKit

struct ContainerDemo: View {
    var body: some View {
        ContainerDemoUIViewWrapper()
    }
}

/// Wraps a UIKit view hierarchy that uses real UIAccessibilityContainerType containers,
/// which the parser can detect (SwiftUI's .accessibilityElement(children:) doesn't
/// set UIAccessibilityContainerType).
private struct ContainerDemoUIViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let root = UIView()
        root.backgroundColor = .systemBackground

        // Semantic group container with label
        let accountGroup = ContainerView(type: .semanticGroup)
        accountGroup.accessibilityLabel = "Account Info"
        let header = makeLabel("Account Summary", font: .preferredFont(forTextStyle: .headline))
        let balance = makeLabel("Balance: $1,234.56")
        let updated = makeLabel("Last updated: Today")
        accountGroup.addSubview(header)
        accountGroup.addSubview(balance)
        accountGroup.addSubview(updated)

        // List container
        let transactionList = ContainerView(type: .list)
        let listHeader = makeLabel("Recent Transactions", font: .preferredFont(forTextStyle: .subheadline, weight: .semibold))
        let tx1 = makeLabel("Coffee Shop - $4.50")
        let tx2 = makeLabel("Grocery Store - $52.30")
        let tx3 = makeLabel("Gas Station - $35.00")
        transactionList.addSubview(listHeader)
        transactionList.addSubview(tx1)
        transactionList.addSubview(tx2)
        transactionList.addSubview(tx3)

        // Button outside any container
        let button = UIButton(type: .system)
        button.setTitle("View All Transactions", for: .normal)
        button.sizeToFit()

        root.addSubview(accountGroup)
        root.addSubview(transactionList)
        root.addSubview(button)

        // Layout
        let padding: CGFloat = 16
        let spacing: CGFloat = 16
        var y = padding

        for container in [accountGroup, transactionList] {
            var childY: CGFloat = 8
            for subview in container.subviews {
                subview.sizeToFit()
                subview.frame.origin = CGPoint(x: 8, y: childY)
                childY = subview.frame.maxY + 4
            }
            container.frame = CGRect(x: padding, y: y, width: 300, height: childY + 8)
            y = container.frame.maxY + spacing
        }

        button.frame.origin = CGPoint(x: padding, y: y)
        y = button.frame.maxY + padding

        root.frame = CGRect(x: 0, y: 0, width: 332, height: y)
        return root
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func makeLabel(_ text: String, font: UIFont = .preferredFont(forTextStyle: .body)) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.isAccessibilityElement = true
        return label
    }
}

private extension UIFont {
    static func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: desc, size: 0)
    }
}

/// A UIView that reports itself as an accessibility container of a specific type.
private class ContainerView: UIView {
    private let containerType: UIAccessibilityContainerType

    init(type: UIAccessibilityContainerType) {
        containerType = type
        super.init(frame: .zero)
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var accessibilityContainerType: UIAccessibilityContainerType {
        get { containerType }
        set {}
    }
}

#Preview("Containers") {
    ContainerDemo()
        .accessibilityPreview(
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
}

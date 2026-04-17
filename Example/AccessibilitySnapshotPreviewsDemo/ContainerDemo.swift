import AccessibilitySnapshotPreviews
import SwiftUI
import UIKit

struct ContainerDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DemoSection(title: "Account Info", description: "Semantic group container") {
                Text("Balance: $1,234.56")
                Text("Last updated: Today")
            }
            .semanticGroupContainer(label: "Account Info")

            DemoSection(title: "Transactions", description: "Another semantic group") {
                Text("Coffee Shop - $4.50")
                Text("Grocery Store - $52.30")
                Text("Gas Station - $35.00")
            }
            .semanticGroupContainer(label: "Transactions")

            Button("View All Transactions") {}
                .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Semantic Group Container

/// A SwiftUI modifier that wraps the content in a UIKit view with
/// `accessibilityContainerType = .semanticGroup`, since SwiftUI has no native equivalent.
private extension View {
    func semanticGroupContainer(label: String? = nil) -> some View {
        SemanticGroupWrapper(label: label) { self }
    }
}

private struct SemanticGroupWrapper<Content: View>: UIViewRepresentable {
    let label: String?
    let content: Content

    init(label: String?, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    func makeUIView(context: Context) -> SemanticGroupUIView {
        let container = SemanticGroupUIView()
        container.accessibilityLabel = label

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

    func updateUIView(_ uiView: SemanticGroupUIView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        uiView.accessibilityLabel = label
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var hostingController: UIHostingController<Content>?
    }
}

/// A UIView that reports itself as a semantic group accessibility container.
private class SemanticGroupUIView: UIView {
    override var accessibilityContainerType: UIAccessibilityContainerType {
        get { .semanticGroup }
        set {}
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Previews

#Preview {
    ContainerDemo()
        .accessibilityPreview()
}

#Preview("Containers") {
    ContainerDemo()
        .accessibilityPreview(
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
}

import AccessibilitySnapshotPreviews
import SwiftUI
import UIKit

/// Exercises every info variant of `accessibilityContainerType = .semanticGroup`:
/// label only, label + value, identifier only, and all three populated together.
struct ContainerDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoSection(title: "Label only", description: "label = \"Account Info\"") {
                Text("Balance: $1,234.56")
                Text("Last updated: Today")
            }
            .accessibilityContainer(type: .semanticGroup, label: "Account Info")

            DemoSection(title: "Label + value", description: "+ value = \"Premium\"") {
                Text("Plan: Premium")
                Text("Renews: Dec 1")
            }
            .accessibilityContainer(type: .semanticGroup, label: "Subscription", value: "Premium")

            DemoSection(title: "Identifier only", description: "id = \"profile.card\"") {
                Text("Jane Doe")
                Text("jane@example.com")
            }
            .accessibilityContainer(type: .semanticGroup, identifier: "profile.card")

            DemoSection(title: "All three", description: "label + value + id") {
                Text("2 unread messages")
            }
            .accessibilityContainer(
                type: .semanticGroup,
                label: "Inbox",
                value: "2 unread",
                identifier: "inbox.card"
            )

            Spacer()
        }
        .padding()
    }
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

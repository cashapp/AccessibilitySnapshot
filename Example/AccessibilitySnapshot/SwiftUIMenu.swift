import SwiftUI

@available(iOS 14.0, *)
struct SwiftUIMenu: View {
    var body: some View {
        VStack(spacing: 30) {
            // Basic menu with label and actions.
            Menu("Actions") {
                Button("Copy", action: {})
                Button("Paste", action: {})
                Button("Delete", action: {})
            }

            // Menu with a custom label.
            Menu {
                Button("Option A", action: {})
                Button("Option B", action: {})
            } label: {
                Label("More Options", systemImage: "ellipsis.circle")
            }

            // Nested menu.
            Menu("Nested Menu") {
                Button("Top-Level Action", action: {})
                Menu("Submenu") {
                    Button("Submenu Action 1", action: {})
                    Button("Submenu Action 2", action: {})
                }
            }

            // Menu with accessibility modifiers.
            Menu("Accessible Menu") {
                Button("Action", action: {})
            }
            .accessibilityLabel("Custom Menu Label")
            .accessibilityHint("Opens a list of actions")

            Spacer()
        }
        .padding()
    }
}

import SwiftUI

/// Demonstrates how `.swipeActions` interacts with `.accessibilityAction(named:)` and the
/// parser's deduplication/precedence logic.
@available(iOS 15.0, *)
struct SwiftUISwipeActionsDemo: View {
    var body: some View {
        List {
            Section {
                swipeOnlyRow
            } header: {
                Text("Swipe Action Only")
            } footer: {
                Text("Action surfaced via private API only")
            }

            Section {
                swipeWithMatchingAccessibilityRow
            } header: {
                Text("Swipe + Accessibility (Same Name)")
            } footer: {
                Text("Duplicate is deduplicated — one action shown")
            }

            Section {
                swipeWithDifferentAccessibilityRow
            } header: {
                Text("Swipe + Accessibility (Different Names)")
            } footer: {
                Text("Both actions shown — public takes precedence")
            }

            Section {
                multiElementRow
            } header: {
                Text("Multi-Element Row")
            } footer: {
                Text("Two buttons in one row with a swipe action")
            }
        }
        .navigationTitle("Swipe Actions")
    }

    /// Row 1: `.swipeActions` only — action discovered via private selector.
    private var swipeOnlyRow: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Margherita Pizza")
                    .font(.headline)
                Text("$12")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .swipeActions(edge: .trailing) {
            Button("Add to Order") {}
        }
    }

    /// Row 2: `.swipeActions` + `.accessibilityAction` with the same name — should deduplicate.
    private var swipeWithMatchingAccessibilityRow: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Caesar Salad")
                    .font(.headline)
                Text("$9")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .swipeActions(edge: .trailing) {
            Button("Add to Order") {}
        }
        .accessibilityAction(named: "Add to Order") {}
    }

    /// Row 3: `.swipeActions` + `.accessibilityAction` with different names — both should appear.
    private var swipeWithDifferentAccessibilityRow: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Tiramisu")
                    .font(.headline)
                Text("$8")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .swipeActions(edge: .trailing) {
            Button("Add to Order") {}
        }
        .accessibilityAction(named: "Save for Later") {}
    }

    /// Row 4: Two separate accessibility elements in one row with a swipe action.
    private var multiElementRow: some View {
        HStack {
            Button("First") {}
            Button("Second") {}
        }
        .swipeActions(edge: .trailing) {
            Button("Row Action") {}
        }
    }
}

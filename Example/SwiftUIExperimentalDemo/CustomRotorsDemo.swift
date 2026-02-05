import SwiftUI
import SwiftUI_Experimental

/// Demonstrates SwiftUI accessibility rotors using the namespace pattern.
///
/// This example shows a restaurant menu where VoiceOver users can use the
/// "Vegan Options" rotor to quickly navigate between plant-based items.
///
/// ## Key Pattern
/// For rotor results to be programmatically accessible (e.g., in snapshot tests),
/// you MUST use the namespace pattern:
///
/// 1. Declare a namespace: `@Namespace private var myNamespace`
/// 2. Mark target elements: `.accessibilityRotorEntry(id: item.id, in: myNamespace)`
/// 3. Define rotor with namespace: `AccessibilityRotorEntry(..., id: item.id, in: myNamespace)`
struct CustomRotorsDemo: View {
    @Namespace private var veganRotorNamespace

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                menuSection
            }
            .padding()
        }
        .navigationTitle("Custom Rotors")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Restaurant Menu")
                .font(.headline)

            Text("VoiceOver users can use the \"Vegan Options\" rotor to quickly navigate between plant-based menu items.")
                .font(.caption)
                .foregroundStyle(.secondary)
                // Attach the rotor to the description text (element 2)
                .accessibilityRotor("Vegan Options") {
                    ForEach(veganItems) { item in
                        AccessibilityRotorEntry(Text(item.name), id: item.id, in: veganRotorNamespace)
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var menuSection: some View {
        VStack(spacing: 8) {
            ForEach(menuItems) { item in
                MenuItemRow(item: item, namespace: veganRotorNamespace)
            }
        }
    }

    // MARK: - Data

    private struct MenuItem: Identifiable {
        let id: String
        let name: String
        let price: String
        let isVegan: Bool
    }

    private let menuItems: [MenuItem] = [
        MenuItem(id: "burger", name: "Classic Burger", price: "$12", isVegan: false),
        MenuItem(id: "salad", name: "Garden Salad", price: "$9", isVegan: true),
        MenuItem(id: "steak", name: "Ribeye Steak", price: "$28", isVegan: false),
        MenuItem(id: "falafel", name: "Falafel Wrap", price: "$11", isVegan: true),
        MenuItem(id: "salmon", name: "Grilled Salmon", price: "$22", isVegan: false),
        MenuItem(id: "buddha", name: "Buddha Bowl", price: "$14", isVegan: true),
    ]

    private var veganItems: [MenuItem] {
        menuItems.filter { $0.isVegan }
    }

    // MARK: - Menu Item Row

    private struct MenuItemRow: View {
        let item: MenuItem
        let namespace: Namespace.ID

        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(item.price)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if item.isVegan {
                    Text("Vegan")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(item.isVegan ? Color.green.opacity(0.1) : Color(.tertiarySystemBackground))
            .cornerRadius(8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(item.name), \(item.price)\(item.isVegan ? ", Vegan" : "")")
            // KEY: Only vegan items are marked as rotor entry targets
            .modifier(VeganRotorEntryModifier(item: item, namespace: namespace))
        }
    }

    /// Conditionally applies accessibilityRotorEntry only for vegan items
    private struct VeganRotorEntryModifier: ViewModifier {
        let item: MenuItem
        let namespace: Namespace.ID

        func body(content: Content) -> some View {
            if item.isVegan {
                content.accessibilityRotorEntry(id: item.id, in: namespace)
            } else {
                content
            }
        }
    }
}

#Preview {
    CustomRotorsDemo()
        .accessibilityPreview()
}

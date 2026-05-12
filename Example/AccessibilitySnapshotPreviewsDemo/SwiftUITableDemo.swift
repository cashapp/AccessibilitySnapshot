import AccessibilitySnapshotPreviews
import SwiftUI

/// Demonstrates how native `SwiftUI.Table` surfaces accessibility containers.
/// On iPhone, `Table` collapses to a single-column list, so the accessibility tree
/// reflects that layout rather than a true `.dataTable` container.
struct SwiftUITableDemo: View {
    struct Sale: Identifiable {
        let id = UUID()
        let quarter: String
        let revenue: String
        let growth: String
    }

    private let sales: [Sale] = [
        Sale(quarter: "Q1", revenue: "$10", growth: "+5%"),
        Sale(quarter: "Q2", revenue: "$15", growth: "+50%"),
        Sale(quarter: "Q3", revenue: "$12", growth: "-20%"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoSection(title: "SwiftUI Table", description: "native Table") {
                Table(sales) {
                    TableColumn("Quarter", value: \.quarter)
                    TableColumn("Revenue", value: \.revenue)
                    TableColumn("Growth", value: \.growth)
                }
                .frame(height: 220)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SwiftUITableDemo()
        .accessibilityPreview(
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
}

import AccessibilitySnapshotPreviews
import SwiftUI

/// Exercises `accessibilityContainerType = .dataTable` with real
/// `UIAccessibilityContainerDataTableCell` elements. Each cell has its own row/column
/// range, which VoiceOver announces and which the legend shows as "Data Table (r × c)"
/// plus per-cell row/column context.
struct DataTableContainerDemo: View {
    private let cells = [
        ["Q1", "Q2", "Q3", "Q4"],
        ["$10", "$15", "$12", "$20"],
        ["$11", "$18", "$14", "$22"],
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoSection(
                title: "Sales by quarter",
                description: ".dataTable(\(cells.count) × \(cells[0].count))"
            ) {
                AccessibilityDataTable(cells: cells)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    DataTableContainerDemo()
        .accessibilityPreview(
            configuration: .init(viewRenderingMode: .drawHierarchyInRect, showContainers: true)
        )
}

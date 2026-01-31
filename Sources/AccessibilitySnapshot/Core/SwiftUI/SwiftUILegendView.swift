import AccessibilitySnapshotParser
import SwiftUI

/// Displays the complete legend with all accessibility elements (SwiftUI version).
struct SwiftUILegendView: View {
    let markers: [AccessibilityMarker]
    let palette: AccessibilityColorPalette
    let showUserInputLabels: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LegendLayoutMetrics.legendVerticalSpacing) {
            Text("\(markers.count) \(markers.count == 1 ? "element" : "elements")")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            ForEach(markers.indices, id: \.self) { index in
                LegendEntryView(
                    index: index,
                    marker: markers[index],
                    palette: palette,
                    showUserInputLabels: showUserInputLabels
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

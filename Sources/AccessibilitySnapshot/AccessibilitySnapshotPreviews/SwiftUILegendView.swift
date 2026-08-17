import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Displays the complete legend with all accessibility elements.
@available(iOS 16.0, *)
public struct LegendView: View {
    public let markers: [AccessibilityMarker]
    public let palette: ColorPalette
    public let inputLabelDisplayMode: AccessibilityContentDisplayMode
    public let showUnspokenTraits: Bool

    public init(
        markers: [AccessibilityMarker],
        palette: ColorPalette,
        inputLabelDisplayMode: AccessibilityContentDisplayMode,
        showUnspokenTraits: Bool = true
    ) {
        self.markers = markers
        self.palette = palette
        self.inputLabelDisplayMode = inputLabelDisplayMode
        self.showUnspokenTraits = showUnspokenTraits
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LegendLayoutMetrics.legendVerticalSpacing) {
            ForEach(markers.indices, id: \.self) { index in
                LegendEntryView(
                    index: index,
                    marker: markers[index],
                    palette: palette,
                    inputLabelDisplayMode: inputLabelDisplayMode,
                    showUnspokenTraits: showUnspokenTraits
                )
            }
        }
        .padding(LegendLayoutMetrics.legendInset)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

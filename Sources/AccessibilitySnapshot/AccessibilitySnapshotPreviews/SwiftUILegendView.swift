import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Displays the complete legend with all accessibility elements.
@available(iOS 16.0, *)
public struct LegendView: View {
    public let markers: [AccessibilityMarker]
    public let palette: ColorPalette
    private let configuration: AccessibilitySnapshotConfiguration

    public var showUserInputLabels: Bool {
        configuration.inputLabelDisplayMode != .never
    }

    public var showUnspokenTraits: Bool {
        configuration.showsUnspokenTraits
    }

    public init(
        markers: [AccessibilityMarker],
        palette: ColorPalette,
        showUserInputLabels: Bool,
        showUnspokenTraits: Bool = true
    ) {
        self.init(
            markers: markers,
            palette: palette,
            configuration: .init(
                viewRenderingMode: .drawHierarchyInRect,
                includesInputLabels: showUserInputLabels ? .whenOverridden : .never,
                showsUnspokenTraits: showUnspokenTraits
            )
        )
    }

    public init(
        markers: [AccessibilityMarker],
        palette: ColorPalette,
        configuration: AccessibilitySnapshotConfiguration
    ) {
        self.markers = markers
        self.palette = palette
        self.configuration = configuration
    }

    public var body: some View {
        if markers.isEmpty {
            // An empty legend would still lay out `legendInset` on every edge.
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: LegendLayoutMetrics.legendVerticalSpacing) {
                ForEach(markers.indices, id: \.self) { index in
                    LegendEntryView(
                        index: index,
                        marker: markers[index],
                        palette: palette,
                        configuration: configuration
                    )
                }
            }
            // Text in the legend must always wrap rather than truncate, even when the enclosing
            // layout proposes less height than the entries need.
            .fixedSize(horizontal: false, vertical: true)
            .padding(LegendLayoutMetrics.legendInset)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

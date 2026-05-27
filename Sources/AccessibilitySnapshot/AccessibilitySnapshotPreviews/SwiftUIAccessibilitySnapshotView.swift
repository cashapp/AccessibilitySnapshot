import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// A SwiftUI view that displays a rendered snapshot with accessibility overlays and legend.
///
/// Callers supply the already-parsed snapshot data (image, markers, optional hierarchy). The
/// live-parsing entry point used by `View.accessibilityPreview()` is a private wrapper that
/// runs the parser and then constructs this view; tests construct it directly from
/// `SwiftUIAccessibilitySnapshotContainerView`.
@available(iOS 16.0, *)
public struct AccessibilitySnapshotView: View {
    private let snapshotImage: UIImage
    private let markers: [AccessibilityMarker]
    private let hierarchy: [AccessibilityHierarchy]
    private let configuration: AccessibilitySnapshotConfiguration
    private let palette: ColorPalette
    private let renderSize: CGSize

    public init(
        snapshotImage: UIImage,
        markers: [AccessibilityMarker],
        hierarchy: [AccessibilityHierarchy] = [],
        configuration: AccessibilitySnapshotConfiguration = .init(viewRenderingMode: .drawHierarchyInRect),
        palette: ColorPalette = .default,
        renderSize: CGSize
    ) {
        self.snapshotImage = snapshotImage
        self.markers = markers
        self.hierarchy = hierarchy
        self.configuration = configuration
        self.palette = palette
        self.renderSize = renderSize
    }

    private var showsHierarchyLegend: Bool {
        configuration.showContainers && !hierarchy.isEmpty
    }

    private var showUserInputLabels: Bool {
        configuration.inputLabelDisplayMode != .never
    }

    private var showUnspokenTraits: Bool {
        configuration.showsUnspokenTraits
    }

    // Mirrors UIKit's `legendLocation`: place the legend on the right only when the view is
    // taller than wide and at least as wide as the legend's minimum footprint; otherwise
    // it goes below.
    private var legendOnRight: Bool {
        let aspectRatio = renderSize.width / renderSize.height
        return aspectRatio <= 1 && renderSize.width >= LegendLayoutMetrics.minimumWidth
    }

    private var contentWidth: CGFloat {
        max(renderSize.width, LegendLayoutMetrics.minimumWidth)
    }

    public var body: some View {
        if legendOnRight {
            HStack(alignment: .top, spacing: 0) {
                snapshotWithOverlays
                legendSideContent
            }
            .background(Color(white: 0.9))
        } else {
            VStack(spacing: 0) {
                snapshotWithOverlays
                    .frame(width: contentWidth)
                legendBottomContent
                    .frame(width: contentWidth)
            }
            .background(Color(white: 0.9))
        }
    }

    private func hierarchyLegend(availableHeight: CGFloat? = nil) -> HierarchyLegendView {
        HierarchyLegendView(
            hierarchy: hierarchy,
            palette: palette,
            showUserInputLabels: showUserInputLabels,
            showUnspokenTraits: showUnspokenTraits,
            availableHeight: availableHeight
        )
    }

    @ViewBuilder
    private var legendSideContent: some View {
        if showsHierarchyLegend {
            // Side legends share vertical space with the snapshot — flow entries across
            // columns so deep hierarchies don't overflow the snapshot height.
            let availableHeight = renderSize.height - LegendLayoutMetrics.legendInset * 2
            hierarchyLegend(availableHeight: availableHeight)
                .frame(minWidth: LegendLayoutMetrics.minimumLegendWidth, alignment: .topLeading)
                .padding(LegendLayoutMetrics.legendInset)
        } else {
            multiColumnLegend
        }
    }

    @ViewBuilder
    private var legendBottomContent: some View {
        if showsHierarchyLegend {
            hierarchyLegend()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(LegendLayoutMetrics.legendInset)
        } else {
            LegendView(
                markers: markers,
                palette: palette,
                showUserInputLabels: showUserInputLabels,
                showUnspokenTraits: showUnspokenTraits
            )
        }
    }

    @ViewBuilder
    private var multiColumnLegend: some View {
        let availableHeight = renderSize.height - LegendLayoutMetrics.legendInset * 2

        ColumnWrapLayout(
            availableHeight: availableHeight,
            columnWidth: LegendLayoutMetrics.minimumLegendWidth,
            horizontalSpacing: LegendLayoutMetrics.legendHorizontalSpacing,
            verticalSpacing: LegendLayoutMetrics.legendVerticalSpacing
        ) {
            ForEach(markers.indices, id: \.self) { index in
                LegendEntryView(
                    index: index,
                    marker: markers[index],
                    palette: palette,
                    showUserInputLabels: showUserInputLabels,
                    showUnspokenTraits: showUnspokenTraits
                )
            }
        }
        .padding(LegendLayoutMetrics.legendInset)
    }

    private var snapshotWithOverlays: some View {
        SnapshotOverlayView(
            snapshotImage: snapshotImage,
            markers: markers,
            palette: palette,
            renderSize: renderSize,
            activationPointDisplayMode: configuration.activationPointDisplayMode
        )
    }
}

// MARK: - Snapshot Overlay View

/// Snapshot image + element overlays as a SwiftUI view.
@available(iOS 16.0, *)
private struct SnapshotOverlayView: View {
    let snapshotImage: UIImage
    let markers: [AccessibilityMarker]
    let palette: ColorPalette
    let renderSize: CGSize
    let activationPointDisplayMode: AccessibilityContentDisplayMode

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: snapshotImage)
                .resizable()
                .frame(width: renderSize.width, height: renderSize.height)

            ForEach(markers.indices, id: \.self) { index in
                let marker = markers[index]
                ElementOverlay(
                    index: index,
                    shape: marker.shape,
                    palette: palette
                )

                if shouldShowActivationPoint(for: marker) {
                    ActivationPointView(
                        position: marker.activationPoint,
                        color: palette.strokeColor(at: index)
                    )
                }
            }
        }
        .frame(width: renderSize.width, height: renderSize.height)
        .clipped()
    }

    private func shouldShowActivationPoint(for marker: AccessibilityMarker) -> Bool {
        switch activationPointDisplayMode {
        case .always:
            return true
        case .whenOverridden:
            return !marker.usesDefaultActivationPoint
        case .never:
            return false
        }
    }
}

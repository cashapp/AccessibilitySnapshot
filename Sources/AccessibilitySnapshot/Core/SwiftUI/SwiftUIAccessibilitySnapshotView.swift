import AccessibilitySnapshotParser
import SwiftUI

@available(iOS 16.0, *)
public extension View {
    func accessibilityPreview(
        palette: AccessibilityColorPalette = .default,
        renderSize: CGSize? = nil
    ) -> some View {
        SwiftUIAccessibilitySnapshotView(
            content: { self },
            palette: palette,
            renderSize: renderSize
        )
    }
}

/// A SwiftUI container view that displays a snapshot with accessibility overlays and legend.
@available(iOS 16.0, *)
public struct SwiftUIAccessibilitySnapshotView<Content: View>: View {
    private let content: Content
    private let palette: AccessibilityColorPalette
    private let activationPointDisplayMode: AccessibilityContentDisplayMode
    private let showUserInputLabels: Bool
    private let renderSize: CGSize

    @State private var markers: [AccessibilityMarker] = []
    @State private var snapshotImage: UIImage?
    @State private var parseError: Error?

    public init(
        @ViewBuilder content: () -> Content,
        palette: AccessibilityColorPalette = .default,
        activationPointDisplayMode: AccessibilityContentDisplayMode = .whenOverridden,
        showUserInputLabels: Bool = false,
        renderSize: CGSize? = nil
    ) {
        self.content = content()
        self.palette = palette
        self.activationPointDisplayMode = activationPointDisplayMode
        self.showUserInputLabels = showUserInputLabels
        self.renderSize = renderSize ?? UIScreen.main.bounds.size
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let snapshotImage = snapshotImage {
                snapshotWithOverlays(image: snapshotImage)
            } else if let parseError = parseError {
                errorView(error: parseError)
            }

            SwiftUILegendView(
                markers: markers,
                palette: palette,
                showUserInputLabels: showUserInputLabels
            )
            .frame(width: renderSize.width)
        }
        .onAppear {
            // Only parse if we don't already have pre-parsed data
            if snapshotImage == nil {
                parseAccessibility()
            }
        }
        .background(Color.white)
    }

    // MARK: - Private Views

    @ViewBuilder
    private func snapshotWithOverlays(image: UIImage) -> some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: image)
                .resizable()
                .frame(width: renderSize.width, height: renderSize.height)

            ForEach(markers.indices, id: \.self) { index in
                let marker = markers[index]

                ElementView(
                    index: index,
                    palette: palette,
                    mode: .overlay(shape: marker.shape)
                )

                if shouldShowActivationPoint(for: marker) {
                    ActivationPointView(
                        position: marker.activationPoint,
                        color: palette.solidColor(at: index)
                    )
                }
            }
        }
        .frame(width: renderSize.width, height: renderSize.height)
    }

    @ViewBuilder
    private func errorView(error: Error) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error.localizedDescription)
        }
        content
    }

    // MARK: - Private Methods

    private func parseAccessibility() {
        let adjustedContent = content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)

        let hostingController = UIHostingController(rootView: adjustedContent)
        hostingController.view.frame = CGRect(origin: .zero, size: renderSize)

        do {
            snapshotImage = try hostingController.view.renderToImage(
                monochrome: false,
                viewRenderingMode: .drawHierarchyInRect
            )

            let parser = AccessibilityHierarchyParser()
            markers = parser.parseAccessibilityElements(in: hostingController.view)
        } catch {
            parseError = error
        }
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

// MARK: - UIView Wrapper

@available(iOS 16.0, *)
public extension SwiftUIAccessibilitySnapshotView where Content == UIViewWrapper {
    /// Creates a snapshot view wrapping a UIView.
    init(
        containedView: UIView,
        palette: AccessibilityColorPalette = .default,
        activationPointDisplayMode: AccessibilityContentDisplayMode = .whenOverridden,
        showUserInputLabels: Bool = false,
        renderSize: CGSize? = nil
    ) {
        content = UIViewWrapper(view: containedView)
        self.palette = palette
        self.activationPointDisplayMode = activationPointDisplayMode
        self.showUserInputLabels = showUserInputLabels
        self.renderSize = renderSize ?? containedView.bounds.size
    }
}

// MARK: - Pre-parsed Snapshot View

/// A SwiftUI view that displays a pre-rendered snapshot with accessibility overlays and legend.
/// This is used when the UIView has already been snapshotted and parsed.
@available(iOS 16.0, *)
public struct PreParsedAccessibilitySnapshotView: View {
    private let snapshotImage: UIImage
    private let markers: [AccessibilityMarker]
    private let palette: AccessibilityColorPalette
    private let activationPointDisplayMode: AccessibilityContentDisplayMode
    private let showUserInputLabels: Bool
    private let renderSize: CGSize

    public init(
        snapshotImage: UIImage,
        markers: [AccessibilityMarker],
        palette: AccessibilityColorPalette = .default,
        activationPointDisplayMode: AccessibilityContentDisplayMode = .whenOverridden,
        showUserInputLabels: Bool = false,
        renderSize: CGSize
    ) {
        self.snapshotImage = snapshotImage
        self.markers = markers
        self.palette = palette
        self.activationPointDisplayMode = activationPointDisplayMode
        self.showUserInputLabels = showUserInputLabels
        self.renderSize = renderSize
    }

    private var legendOnRight: Bool {
        let aspectRatio = renderSize.width / renderSize.height
        // Wide views (aspectRatio > 1) or small views should display legend below
        return aspectRatio <= 1 && renderSize.width >= LegendLayoutMetrics.minimumLegendWidth
    }

    /// Minimum content width to ensure legend fits properly
    private var contentWidth: CGFloat {
        max(renderSize.width, LegendLayoutMetrics.minimumWidth)
    }

    public var body: some View {
        if legendOnRight {
            // Tall view: snapshot on left, legend on right (may span multiple columns)
            HStack(alignment: .top, spacing: 0) {
                snapshotWithOverlays
                multiColumnLegend
            }
            .background(Color(white: 0.9))
        } else {
            // Wide view: snapshot on top, legend on bottom
            VStack(spacing: 0) {
                snapshotWithOverlays
                    .frame(width: contentWidth) // Center snapshot if smaller than legend
                SwiftUILegendView(
                    markers: markers,
                    palette: palette,
                    showUserInputLabels: showUserInputLabels
                )
                .frame(width: contentWidth - LegendLayoutMetrics.legendInset * 2)
                .padding(LegendLayoutMetrics.legendInset)
            }
            .background(Color(white: 0.9))
        }
    }

    /// Wraps legend items into multiple columns when they exceed the available height
    @ViewBuilder
    private var multiColumnLegend: some View {
        // Match UIKit's available height calculation exactly (no multiplier!)
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
                    showUserInputLabels: showUserInputLabels
                )
            }
        }
        .padding(LegendLayoutMetrics.legendInset)
    }

    private var snapshotWithOverlays: some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: snapshotImage)
                .resizable()
                .frame(width: renderSize.width, height: renderSize.height)

            ForEach(markers.indices, id: \.self) { index in
                let marker = markers[index]
                ElementView(
                    index: index,
                    palette: palette,
                    mode: .overlay(shape: marker.shape)
                )

                if shouldShowActivationPoint(for: marker) {
                    ActivationPointView(
                        position: marker.activationPoint,
                        color: palette.solidColor(at: index)
                    )
                }
            }
        }
        .frame(width: renderSize.width, height: renderSize.height)
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

/// A SwiftUI wrapper for UIView.
public struct UIViewWrapper: View {
    let view: UIView

    public var body: some View {
        UIViewWrapperRepresentable(view: view)
    }
}

private struct UIViewWrapperRepresentable: UIViewRepresentable {
    let view: UIView

    func makeUIView(context: Context) -> UIView {
        view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Helpers

private extension CGSize {
    var aspectRatio: CGFloat {
        width / height
    }
}

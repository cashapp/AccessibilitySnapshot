import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

// Note: The `.accessibilityPreview()` View extension is provided by the AccessibilityPreviews module.

/// A SwiftUI container view that displays a snapshot with accessibility overlays and legend.
@available(iOS 18.0, *)
public struct AccessibilitySnapshotView<Content: View>: View {
    private let content: Content
    private let configuration: AccessibilitySnapshotConfiguration
    private let palette: ColorPalette
    private let renderSize: CGSize

    @State private var markers: [AccessibilityMarker] = []
    @State private var snapshotImage: UIImage?
    @State private var parseError: Error?

    public init(
        @ViewBuilder content: () -> Content,
        configuration: AccessibilitySnapshotConfiguration = .init(viewRenderingMode: .drawHierarchyInRect),
        palette: ColorPalette = .default,
        renderSize: CGSize? = nil
    ) {
        self.content = content()
        self.configuration = configuration
        self.palette = palette
        self.renderSize = renderSize ?? UIScreen.main.bounds.size
    }

    private var showUserInputLabels: Bool {
        configuration.inputLabelDisplayMode != .never
    }

    private var showUnspokenTraits: Bool {
        configuration.showsUnspokenTraits
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let snapshotImage = snapshotImage {
                snapshotWithOverlays(image: snapshotImage)
            } else if let parseError = parseError {
                errorView(error: parseError)
            }

            LegendView(
                markers: markers,
                palette: palette,
                showUserInputLabels: showUserInputLabels,
                showUnspokenTraits: showUnspokenTraits
            )
            .frame(width: renderSize.width)
        }
        .onAppear {
            // Only parse if we don't already have pre-parsed data
            if snapshotImage == nil {
                parseAccessibility()
            }
        }
        .background(Color(white: 0.9))
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
                        color: palette.strokeColor(at: index)
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
                configuration: configuration.rendering
            )

            let parser = AccessibilityHierarchyParser()
            markers = parser.parseAccessibilityElements(
                in: hostingController.view,
                rotorResultLimit: configuration.rotors.resultLimit
            )
        } catch {
            parseError = error
        }
    }

    private func shouldShowActivationPoint(for marker: AccessibilityMarker) -> Bool {
        switch configuration.activationPointDisplayMode {
        case .always:
            return true
        case .whenOverridden:
            return !marker.usesDefaultActivationPoint
        case .never:
            return false
        }
    }
}

/// Backwards compatibility alias.
@available(iOS 18.0, *)
public typealias SwiftUIAccessibilitySnapshotView<Content: View> = AccessibilitySnapshotView<Content>

// MARK: - UIView Wrapper

@available(iOS 18.0, *)
public extension AccessibilitySnapshotView where Content == UIViewWrapper {
    /// Creates a snapshot view wrapping a UIView.
    init(
        containedView: UIView,
        configuration: AccessibilitySnapshotConfiguration = .init(viewRenderingMode: .drawHierarchyInRect),
        palette: ColorPalette = .default,
        renderSize: CGSize? = nil
    ) {
        content = UIViewWrapper(view: containedView)
        self.configuration = configuration
        self.palette = palette
        self.renderSize = renderSize ?? containedView.bounds.size
    }
}

// MARK: - Pre-parsed Snapshot View

/// A SwiftUI view that displays a pre-rendered snapshot with accessibility overlays and legend.
/// This is used when the UIView has already been snapshotted and parsed.
@available(iOS 18.0, *)
public struct PreParsedAccessibilitySnapshotView: View {
    private let snapshotImage: UIImage
    private let markers: [AccessibilityMarker]
    private let configuration: AccessibilitySnapshotConfiguration
    private let palette: ColorPalette
    private let renderSize: CGSize

    public init(
        snapshotImage: UIImage,
        markers: [AccessibilityMarker],
        configuration: AccessibilitySnapshotConfiguration = .init(viewRenderingMode: .drawHierarchyInRect),
        palette: ColorPalette = .default,
        renderSize: CGSize
    ) {
        self.snapshotImage = snapshotImage
        self.markers = markers
        self.configuration = configuration
        self.palette = palette
        self.renderSize = renderSize
    }

    private var showUserInputLabels: Bool {
        configuration.inputLabelDisplayMode != .never
    }

    private var showUnspokenTraits: Bool {
        configuration.showsUnspokenTraits
    }

    private var legendOnRight: Bool {
        let aspectRatio = renderSize.width / renderSize.height
        // Match UIKit's legendLocation logic exactly:
        // Wide views (aspectRatio > 1) or views smaller than minimumWidth should display legend below
        // minimumWidth = minimumLegendWidth + legendInset * 2 (includes padding on both sides)
        let minimumWidth = LegendLayoutMetrics.minimumWidth
        return aspectRatio <= 1 && renderSize.width >= minimumWidth
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
                LegendView(
                    markers: markers,
                    palette: palette,
                    showUserInputLabels: showUserInputLabels,
                    showUnspokenTraits: showUnspokenTraits
                )
                .frame(width: contentWidth)
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
                    showUserInputLabels: showUserInputLabels,
                    showUnspokenTraits: showUnspokenTraits
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
                        color: palette.strokeColor(at: index)
                    )
                }
            }
        }
        .frame(width: renderSize.width, height: renderSize.height)
    }

    private func shouldShowActivationPoint(for marker: AccessibilityMarker) -> Bool {
        switch configuration.activationPointDisplayMode {
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
@available(iOS 18.0, *)
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

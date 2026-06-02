import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// A SwiftUI container view that displays a snapshot with accessibility overlays and legend.
@available(iOS 16.0, *)
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
            if snapshotImage == nil {
                parseAccessibility()
            }
        }
        .background(Color(white: 0.9))
    }

    // MARK: - Private Views

    private func snapshotWithOverlays(image: UIImage) -> some View {
        SnapshotOverlayView(
            snapshotImage: image,
            markers: markers,
            palette: palette,
            renderSize: renderSize,
            activationPointDisplayMode: configuration.activationPointDisplayMode
        )
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

        // UIViewRepresentable views (e.g. PathShapeUIView) report accessibilityPath and
        // accessibilityFrame in screen coordinates via `convert(_:to: nil)`, which requires
        // the view to be installed in a UIWindow. Without one, every view reports (0,0) and
        // the paths collapse to the origin.
        let window = UIWindow(frame: CGRect(origin: .zero, size: renderSize))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()

        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        do {
            snapshotImage = try hostingController.view.renderToImage(
                configuration: configuration.rendering
            )

            let parser = AccessibilityHierarchyParser()
            markers = parser.parseAccessibilityHierarchy(
                in: hostingController.view,
                rotorResultLimit: configuration.rotors.resultLimit
            ).flattenToElements()
        } catch {
            parseError = error
        }
    }
}

/// Backwards compatibility alias.
@available(iOS 16.0, *)
public typealias SwiftUIAccessibilitySnapshotView<Content: View> = AccessibilitySnapshotView<Content>

// MARK: - UIView Wrapper

@available(iOS 16.0, *)
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
@available(iOS 16.0, *)
public struct PreParsedAccessibilitySnapshotView: View {
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

/// A SwiftUI wrapper for UIView.
@available(iOS 16.0, *)
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

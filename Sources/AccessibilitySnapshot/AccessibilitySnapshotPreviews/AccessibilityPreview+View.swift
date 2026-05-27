import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// Adds accessibility preview functionality for Xcode Previews.
@available(iOS 16.0, *)
public extension View {
    /// Wraps the view in an accessibility preview with scrollable legend for Xcode Previews.
    ///
    /// - Parameters:
    ///   - configuration: The configuration for snapshot rendering. Defaults to monochrome.
    ///   - palette: The color palette for accessibility markers. Defaults to the standard palette.
    ///   - size: The size to render the view. Defaults to screen size.
    func accessibilityPreview(
        configuration: AccessibilitySnapshotConfiguration = .init(viewRenderingMode: .drawHierarchyInRect),
        palette: AccessibilityColorPalette = .default,
        size: CGSize? = nil
    ) -> some View {
        ScrollView {
            LiveAccessibilityPreview(
                content: self,
                configuration: configuration,
                palette: palette,
                renderSize: size ?? UIScreen.main.bounds.size
            )
        }
        .background(Color(UIColor.systemGray6))
    }
}

/// Parses the wrapped SwiftUI content on appear, then renders the canonical
/// `AccessibilitySnapshotView` with the parsed data. The only caller is
/// `View.accessibilityPreview()`; tests build `AccessibilitySnapshotView` directly with
/// pre-parsed data from the UIKit pipeline.
@available(iOS 16.0, *)
private struct LiveAccessibilityPreview<Content: View>: View {
    let content: Content
    let configuration: AccessibilitySnapshotConfiguration
    let palette: ColorPalette
    let renderSize: CGSize

    @State private var snapshotImage: UIImage?
    @State private var markers: [AccessibilityMarker] = []
    @State private var hierarchy: [AccessibilityHierarchy] = []
    @State private var parseError: Error?

    var body: some View {
        Group {
            if let snapshotImage {
                AccessibilitySnapshotView(
                    snapshotImage: snapshotImage,
                    markers: markers,
                    hierarchy: hierarchy,
                    configuration: configuration,
                    palette: palette,
                    renderSize: renderSize
                )
            } else if let parseError {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(parseError.localizedDescription)
                }
                content
            }
        }
        .onAppear {
            if snapshotImage == nil {
                parseAccessibility()
            }
        }
    }

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
            let tree = parser.parseAccessibilityHierarchy(
                in: hostingController.view,
                rotorResultLimit: configuration.rotors.resultLimit
            )
            hierarchy = tree
            markers = tree.flattenToElements()
        } catch {
            parseError = error
        }
    }
}

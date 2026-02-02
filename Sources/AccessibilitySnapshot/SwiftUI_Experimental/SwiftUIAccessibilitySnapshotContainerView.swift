import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI
import UIKit

// MARK: -

/// A container view that uses SwiftUI to render accessibility overlays and legend.
///
/// This class extends the base accessibility snapshot view but renders overlays using SwiftUI,
/// wrapping them in a `UIHostingController` as a child view. This provides a unified interface
/// for both UIKit and SwiftUI rendering approaches through the shared `AccessibilitySnapshotBaseView`
/// base class.
@available(iOS 18.0, *)
public final class SwiftUIAccessibilitySnapshotContainerView: AccessibilitySnapshotBaseView {
    // MARK: - Private Properties

    private var hostingController: UIHostingController<AnyView>?

    // MARK: - SnapshotAndLegendView Overrides

    // SwiftUI handles its own legend layout via PreParsedAccessibilitySnapshotView,
    // so we don't use the base class's legend layout system.
    override public var legendViews: [UIView] {
        return []
    }

    override public var minimumLegendWidth: CGFloat {
        return LegendLayoutMetrics.minimumLegendWidth
    }

    // MARK: - AccessibilitySnapshotBaseView Overrides

    override public func cleanUpPreviousOverlays() {
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }

    override public func createOverlays(with data: ParsedAccessibilityData) {
        let palette = ColorPalette(modernColors: snapshotConfiguration.markerColors)

        // Create the SwiftUI view with pre-parsed data
        let swiftUIView = PreParsedAccessibilitySnapshotView(
            snapshotImage: data.image,
            markers: data.markers,
            configuration: snapshotConfiguration,
            palette: palette,
            renderSize: data.containedViewBounds
        )

        // Wrap in UIHostingController
        let hosting = UIHostingController(rootView: AnyView(swiftUIView))
        hosting.safeAreaRegions = [] // Disable safe area insets
        hosting.view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        // Size the hosting controller to fit content
        let targetSize = CGSize(
            width: data.containedViewBounds.width,
            height: UIView.layoutFittingExpandedSize.height
        )
        let fittingSize = hosting.sizeThatFits(in: targetSize)
        hosting.view.frame = CGRect(origin: .zero, size: fittingSize)

        // Add hosting controller's view to fill the container
        addSubview(hosting.view)

        // Hide the base class's snapshotView since SwiftUI renders its own
        snapshotView.isHidden = true

        // Match the container's background to the hosting controller for consistent rendering
        backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        hostingController = hosting
    }

    // MARK: - UIView Overrides

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let hostingController = hostingController else {
            return super.sizeThatFits(size)
        }

        // The hosting controller's sizeThatFits returns the natural size of the SwiftUI content
        return hostingController.sizeThatFits(in: size)
    }

    override public func layoutSubviews() {
        // Don't call super - we're completely replacing the layout with the hosting controller
        hostingController?.view.frame = bounds
    }

    override public var intrinsicContentSize: CGSize {
        guard let hostingController = hostingController else {
            return super.intrinsicContentSize
        }
        return hostingController.sizeThatFits(in: UIView.layoutFittingExpandedSize)
    }
}

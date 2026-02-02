import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI
import UIKit

// MARK: -

/// A container view that uses SwiftUI to render accessibility overlays and legend.
@available(iOS 18.0, *)
public final class SwiftUIAccessibilitySnapshotContainerView: AccessibilitySnapshotBaseView {
    // MARK: - Private Properties

    private var hostingController: UIHostingController<AnyView>?

    // MARK: - SnapshotAndLegendView Overrides

    override public var legendViews: [UIView] {
        return []
    }

    override public var minimumLegendWidth: CGFloat {
        return LegendLayoutMetrics.minimumLegendWidth
    }

    // MARK: - AccessibilitySnapshotBaseView Overrides

    override public func cleanup() {
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }

    override public func render(data: ParsedAccessibilityData) {
        let palette = ColorPalette(modernColors: snapshotConfiguration.markerColors)

        let swiftUIView = PreParsedAccessibilitySnapshotView(
            snapshotImage: data.image,
            markers: data.markers,
            configuration: snapshotConfiguration,
            palette: palette,
            renderSize: data.containedViewBounds
        )

        let hosting = UIHostingController(rootView: AnyView(swiftUIView))
        hosting.safeAreaRegions = []
        hosting.view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        let targetSize = CGSize(
            width: data.containedViewBounds.width,
            height: UIView.layoutFittingExpandedSize.height
        )
        let fittingSize = hosting.sizeThatFits(in: targetSize)
        hosting.view.frame = CGRect(origin: .zero, size: fittingSize)

        addSubview(hosting.view)
        snapshotView.isHidden = true
        backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        hostingController = hosting
    }

    // MARK: - UIView Overrides

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let hostingController = hostingController else {
            return super.sizeThatFits(size)
        }
        return hostingController.sizeThatFits(in: size)
    }

    override public func layoutSubviews() {
        hostingController?.view.frame = bounds
    }

    override public var intrinsicContentSize: CGSize {
        guard let hostingController = hostingController else {
            return super.intrinsicContentSize
        }
        return hostingController.sizeThatFits(in: UIView.layoutFittingExpandedSize)
    }
}

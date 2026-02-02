import AccessibilitySnapshotParser
import UIKit

// MARK: -

/// A container view that displays a snapshot of a view and overlays it with accessibility markers, as well as shows a
/// legend of accessibility descriptions underneath.
///
/// The overlays and legend will be added when `parseAccessibility()` is called. In order for the coordinates to be
/// calculated properly, the view must already be in the view hierarchy.
public final class AccessibilitySnapshotView: AccessibilitySnapshotBaseView {
    // MARK: - Life Cycle

    /// Initializes a new snapshot container view.
    ///
    /// - parameter containedView: The view that should be snapshotted, and for which the accessibility markers should
    /// be generated.
    /// - parameter viewRenderingMode: The method to use when snapshotting the `containedView`.
    /// - parameter markerColors: An array of colors to use for the highlighted regions. These colors will be used in
    /// order, repeating through the array as necessary.
    /// - parameter activationPointDisplayMode: Controls when to show indicators for elements' accessibility activation
    /// points.
    /// - parameter showUserInputLabels: Controls when to show elements' accessibility user input labels (used by Voice Control).

    @available(*, deprecated, message: "Please use `init(containedView:snapshotConfiguration:)` instead.")
    public convenience init(
        containedView: UIView,
        viewRenderingMode: ViewRenderingMode,
        markerColors: [UIColor] = [],
        activationPointDisplayMode: AccessibilityContentDisplayMode,
        showUserInputLabels: Bool
    ) {
        let configuration = AccessibilitySnapshotConfiguration(viewRenderingMode: viewRenderingMode,
                                                               overlayColors: markerColors,
                                                               activationPointDisplay: activationPointDisplayMode,
                                                               includesInputLabels: showUserInputLabels ? .whenOverridden : .never)

        self.init(containedView: containedView, snapshotConfiguration: configuration)
    }

    /// Initializes a new snapshot container view.
    ///
    /// - parameter containedView: The view that should be snapshotted, and for which the accessibility markers should
    /// be generated.
    /// - parameter snapshotConfiguration: The configuration for the visual effects and markers applied to the snapshots.
    override public init(
        containedView: UIView,
        snapshotConfiguration: AccessibilitySnapshotConfiguration
    ) {
        super.init(containedView: containedView, snapshotConfiguration: snapshotConfiguration)
    }

    // MARK: - SnapshotAndLegendView

    override public var legendViews: [UIView] {
        return displayMarkers.map { $0.legendView }
    }

    override public var minimumLegendWidth: CGFloat {
        return LegendView.Metrics.minimumWidth
    }

    // MARK: - Private Properties

    private var displayMarkers: [DisplayMarker] = []

    // MARK: - AccessibilitySnapshotBaseView Overrides

    override public func cleanUpPreviousOverlays() {
        displayMarkers.forEach {
            $0.legendView.removeFromSuperview()
            $0.overlayView.removeFromSuperview()
            $0.activationPointView?.removeFromSuperview()
        }
        displayMarkers = []
    }

    override public func createOverlays(with data: ParsedAccessibilityData) {
        var displayMarkers: [DisplayMarker] = []
        let palette = ColorPalette(legacyColors: snapshotConfiguration.markerColors)

        for (index, marker) in data.markers.enumerated() {
            let baseColor: UIColor = palette.color(at: index)
            let fillColor: UIColor = palette.fillColor(at: index)
            let strokeColor: UIColor = palette.strokeColor(at: index)

            let legendView = LegendView(marker: marker, fillColor: fillColor, configuration: snapshotConfiguration)
            addSubview(legendView)

            let rotorResultsShapes = marker.displayRotors(snapshotConfiguration.rotors.displayMode).flatMap(\.resultMarkers).compactMap(\.shape)

            let overlayView = OverlayView(
                frame: snapshotView.bounds,
                elementShape: marker.shape,
                includedShapes: rotorResultsShapes,
                fillColor: fillColor,
                strokeColor: strokeColor
            )

            snapshotView.addSubview(overlayView)

            var displayMarker = DisplayMarker(
                marker: marker,
                legendView: legendView,
                overlayView: overlayView,
                activationPointView: nil
            )

            switch snapshotConfiguration.activationPointDisplayMode {
            case .whenOverridden:
                if !marker.usesDefaultActivationPoint {
                    fallthrough
                }

            case .always:
                guard containedView.bounds.contains(marker.activationPoint) else {
                    break
                }

                let activationPointView = UIImageView(
                    image: UIImage(named: "Crosshairs", in: Bundle.accessibilitySnapshotResources, compatibleWith: nil)
                )
                activationPointView.bounds.size = .init(width: 16, height: 16)
                activationPointView.center = marker.activationPoint
                activationPointView.tintColor = baseColor
                snapshotView.addSubview(activationPointView)
                displayMarker.activationPointView = activationPointView

            case .never:
                break // No-op.
            }

            displayMarkers.append(displayMarker)
        }
        self.displayMarkers = displayMarkers
    }

    // MARK: - Private Types

    private struct DisplayMarker {
        var marker: AccessibilityMarker

        var legendView: LegendView

        var overlayView: UIView

        var activationPointView: UIView?
    }
}

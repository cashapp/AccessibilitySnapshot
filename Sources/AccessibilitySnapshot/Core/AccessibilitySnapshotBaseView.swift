import AccessibilitySnapshotParser
import UIKit

// MARK: - Parsed Data

/// Result type passed to subclasses for overlay creation.
public struct ParsedAccessibilityData {
    /// The rendered snapshot image of the contained view.
    public let image: UIImage

    /// The parsed accessibility markers.
    public let markers: [AccessibilityMarker]

    /// The bounds size of the contained view.
    public let containedViewBounds: CGSize
}

// MARK: - Base View

/// Base class that handles the shared capture and parse logic for accessibility snapshots.
///
/// Subclasses implement `render(data:)` to generate layout-engine-specific visuals.
open class AccessibilitySnapshotBaseView: SnapshotAndLegendView {
    // MARK: - Public Properties

    /// The configuration for snapshot rendering.
    public let snapshotConfiguration: AccessibilitySnapshotConfiguration

    // MARK: - Internal Properties

    /// The view that will be snapshotted.
    let containedView: UIView

    // MARK: - Life Cycle

    /// Initializes a new snapshot container view.
    ///
    /// - parameter containedView: The view that should be snapshotted, and for which the accessibility markers should
    /// be generated.
    /// - parameter snapshotConfiguration: The configuration for the visual effects and markers applied to the snapshots.
    public init(
        containedView: UIView,
        snapshotConfiguration: AccessibilitySnapshotConfiguration
    ) {
        self.containedView = containedView
        self.snapshotConfiguration = snapshotConfiguration

        super.init(frame: containedView.bounds)

        backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    /// Parse the `containedView`'s accessibility and add appropriate visual elements to represent it.
    ///
    /// This must be called _after_ the view is in the view hierarchy.
    ///
    /// - Throws: Throws a `RenderError` when the view fails to render a snapshot of the `containedView`.
    public func parseAccessibility() throws {
        cleanup()

        let viewController = containedView.next as? UIViewController
        let originalParent = viewController?.parent
        let originalSuperviewAndIndex = containedView.superviewWithSubviewIndex()

        viewController?.removeFromParent()
        addSubview(containedView)

        defer {
            containedView.removeFromSuperview()

            if let (originalSuperview, originalSubviewIndex) = originalSuperviewAndIndex {
                originalSuperview.insertSubview(containedView, at: originalSubviewIndex)
            }

            if let viewController = viewController, let originalParent = originalParent {
                originalParent.addChild(viewController)
            }
        }

        containedView.setNeedsLayout()
        containedView.layoutIfNeeded()

        let image = try containedView.renderToImage(
            configuration: snapshotConfiguration.rendering
        )

        snapshotView.image = image
        snapshotView.bounds.size = containedView.bounds.size

        containedView.layoutIfNeeded()

        let parser = AccessibilityHierarchyParser()
        let markers = parser.parseAccessibilityElements(
            in: containedView,
            rotorResultLimit: snapshotConfiguration.rotors.resultLimit
        )

        let parsedData = ParsedAccessibilityData(
            image: image,
            markers: markers,
            containedViewBounds: containedView.bounds.size
        )

        render(data: parsedData)
    }

    // MARK: - Methods for Subclasses to Override

    /// Cleans up any previously created overlay views.
    open func cleanup() {}

    /// Renders the accessibility overlays and legend.
    ///
    /// - Parameter data: The parsed accessibility data including snapshot image and markers.
    open func render(data: ParsedAccessibilityData) {
        fatalError("Subclasses must implement render(data:)")
    }
}

// MARK: - Helper Extension

extension UIView {
    /// Returns the superview and the index of this view within the superview's subviews array.
    func superviewWithSubviewIndex() -> (UIView, Int)? {
        guard let superview = superview else {
            return nil
        }

        guard let index = superview.subviews.firstIndex(of: self) else {
            fatalError("Internal inconsistency error: view has a superview, but is not a subview of the superview")
        }

        return (superview, index)
    }
}

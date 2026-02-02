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
/// Subclasses implement `createOverlays(with:)` to generate renderer-specific visuals (UIKit or SwiftUI).
/// The `parseAccessibility()` method handles all the common orchestration:
/// - Saving/restoring view controller state
/// - Adding the contained view to the hierarchy
/// - Rendering the view to an image
/// - Parsing the accessibility hierarchy
/// - Calling the subclass to create overlays
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
        // Clean up any previous overlays
        cleanUpPreviousOverlays()

        // Save view controller state
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

        // Force a layout pass after the view is in the hierarchy so that the conversion to screen coordinates works
        // correctly.
        containedView.setNeedsLayout()
        containedView.layoutIfNeeded()

        // Render to image
        let image = try containedView.renderToImage(
            configuration: snapshotConfiguration.rendering
        )

        snapshotView.image = image
        snapshotView.bounds.size = containedView.bounds.size

        // Complete the layout pass after the view is restored to this container, in case it was modified during the
        // rendering process (i.e. when the rendering is tiled and stitched).
        containedView.layoutIfNeeded()

        // Parse accessibility hierarchy
        let parser = AccessibilityHierarchyParser()
        let markers = parser.parseAccessibilityElements(
            in: containedView,
            rotorResultLimit: snapshotConfiguration.rotors.resultLimit
        )

        // Delegate overlay creation to subclass
        let parsedData = ParsedAccessibilityData(
            image: image,
            markers: markers,
            containedViewBounds: containedView.bounds.size
        )

        createOverlays(with: parsedData)
    }

    // MARK: - Methods for Subclasses to Override

    /// Override to clean up renderer-specific overlay views before parsing.
    ///
    /// Called at the beginning of `parseAccessibility()` to remove any previously created overlays.
    open func cleanUpPreviousOverlays() {
        // Default implementation does nothing.
        // Subclasses should remove their overlay views here.
    }

    /// Override to create renderer-specific overlay and legend views.
    ///
    /// - Parameter data: The parsed accessibility data including snapshot image and markers.
    open func createOverlays(with data: ParsedAccessibilityData) {
        fatalError("Subclasses must implement createOverlays(with:)")
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

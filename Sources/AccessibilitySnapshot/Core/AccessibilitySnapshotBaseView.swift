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

    /// Per-scroll-container summaries of off-screen elements trimmed during delivery. Empty when the
    /// configuration's `includesOffscreenElements` is `true` (nothing is trimmed, so nothing to tally).
    public let containerSummaries: [ScrollContainerSummary]

    /// The full parsed hierarchy the markers were flattened from. Renderers that visualize container
    /// structure (the SwiftUI hierarchical legend) read this; the UIKit renderer ignores it.
    public let hierarchy: [AccessibilityHierarchy]

    public init(
        image: UIImage,
        markers: [AccessibilityMarker],
        containedViewBounds: CGSize,
        containerSummaries: [ScrollContainerSummary] = [],
        hierarchy: [AccessibilityHierarchy] = []
    ) {
        self.image = image
        self.markers = markers
        self.containedViewBounds = containedViewBounds
        self.containerSummaries = containerSummaries
        self.hierarchy = hierarchy
    }
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

        // When the caller has already hosted the contained view in a window, parse it in place.
        // Reparenting matters for SwiftUI: iOS strips navigation bar content (e.g. `.searchable`
        // fields) from the accessibility tree unless the hosting view is a direct window subview
        // or its controller is seated in the view controller hierarchy, so moving the view into
        // this container would parse a tree production VoiceOver never sees.
        let requiresTemporaryHosting = (containedView.window == nil)

        let viewController = requiresTemporaryHosting ? containedView.next as? UIViewController : nil
        let originalParent = viewController?.parent
        let originalSuperviewAndIndex = requiresTemporaryHosting ? containedView.superviewWithSubviewIndex() : nil

        if requiresTemporaryHosting {
            viewController?.removeFromParent()
            addSubview(containedView)
        }

        defer {
            if requiresTemporaryHosting {
                containedView.removeFromSuperview()

                if let (originalSuperview, originalSubviewIndex) = originalSuperviewAndIndex {
                    originalSuperview.insertSubview(containedView, at: originalSubviewIndex)
                }

                if let viewController = viewController, let originalParent = originalParent {
                    originalParent.addChild(viewController)
                }
            }
        }

        containedView.setNeedsLayout()
        containedView.layoutIfNeeded()

        if !requiresTemporaryHosting {
            waitForAccessibilityTreeToSettle()
        }

        let image = try containedView.renderToImage(
            configuration: snapshotConfiguration.rendering
        )

        snapshotView.image = image
        snapshotView.bounds.size = containedView.bounds.size

        containedView.layoutIfNeeded()

        let parser = AccessibilityHierarchyParser()
        let hierarchy = parser.parseAccessibilityHierarchy(
            in: containedView,
            rotorResultLimit: snapshotConfiguration.rotors.resultLimit
        )
        let includesOffscreen = snapshotConfiguration.includesOffscreenElements

        // Flatten over the full (unpruned) tree — flattening materializes each element's spoken
        // description from its graph-derived container context, so counts and data-table header text
        // must derive from the complete child set. Prune the flat array by visibility afterwards.
        let elements = hierarchy.flattenToElements(verbosity: snapshotConfiguration.verbosity)

        let parsedData = ParsedAccessibilityData(
            image: image,
            markers: includesOffscreen ? elements : elements.filter { $0.visibility == .onscreen },
            containedViewBounds: containedView.bounds.size,
            // Off-screen elements only get trimmed (and thus summarized) when they aren't included.
            containerSummaries: includesOffscreen ? [] : hierarchy.scrollContainerSummaries(),
            hierarchy: hierarchy
        )

        render(data: parsedData)
    }

    // MARK: - Private Methods

    /// Spins the run loop until two consecutive parses of the contained view produce an identical
    /// hierarchy, so asynchronous accessibility updates settle before the real parse. SwiftUI's
    /// collection-backed containers (`List`) publish their final accessibility frames on a batch
    /// update completion that runs one run loop turn after layout; parsing before it lands captures
    /// transient text-tight frames nondeterministically.
    private func waitForAccessibilityTreeToSettle() {
        let parser = AccessibilityHierarchyParser()
        // Rotor evaluation is expensive and irrelevant to settling; skip it while polling.
        var previous = parser.parseAccessibilityHierarchy(in: containedView, rotorResultLimit: 0)
        for _ in 0 ..< 10 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
            let current = parser.parseAccessibilityHierarchy(in: containedView, rotorResultLimit: 0)
            if current == previous {
                return
            }
            previous = current
        }
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

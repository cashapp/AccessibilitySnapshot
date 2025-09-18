//
//  Copyright 2023 Block Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif




// MARK: -

/// A container view that displays a snapshot of a view and overlays it with accessibility markers, as well as shows a
/// legend of accessibility descriptions underneath.
///
/// The overlays and legend will be added when `parseAccessibility()` is called. In order for the coordinates to be
/// calculated properly, the view must already be in the view hierarchy.
public final class AccessibilitySnapshotView: SnapshotAndLegendView {

    // The configuration struct for snapshot rendering.
    public let snapshotConfiguration: AccessibilitySnapshotConfiguration
    
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

    
    @available(*, deprecated, message:"Please use `init(containedView:snapshotConfiguration:)` instead.")
    
    public convenience init(
        containedView: UIView,
        viewRenderingMode: ViewRenderingMode,
        markerColors: [UIColor] = MarkerColors.defaultColors,
        activationPointDisplayMode: AccessibilityContentDisplayMode,
        showUserInputLabels: Bool
    ) {
        
        let configuration = AccessibilitySnapshotConfiguration(viewRenderingMode:viewRenderingMode,
                                                               overlayColors:markerColors,
                                                               activationPointDisplay: activationPointDisplayMode,
                                                               includesInputLabels: showUserInputLabels  ? .whenOverridden : .never)
        
        self.init(containedView: containedView, snapshotConfiguration: configuration)
    }
    
    /// Initializes a new snapshot container view.
    ///
    /// - parameter containedView: The view that should be snapshotted, and for which the accessibility markers should
    /// be generated.
    /// - parameter viewRenderingMode: The method to use when snapshotting the `containedView`.
    /// - parameter snapshotConfiguration: The configuration for the visual effects and markers applied to the snapshots.
    public init(
        containedView: UIView,
        viewRenderingMode: ViewRenderingMode,
        snapshotConfiguration: AccessibilitySnapshotConfiguration
    ) {
        self.containedView = containedView
        self.snapshotConfiguration = snapshotConfiguration
        
        super.init(frame: containedView.bounds)

        backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - SnapshotAndLegendView

    override var legendViews: [UIView] {
        return displayMarkers.map { $0.legendView }
    }

    override var minimumLegendWidth: CGFloat {
        return LegendView.Metrics.minimumWidth
    }

    // MARK: - Private Properties

    private let containedView: UIView

    private var displayMarkers: [DisplayMarker] = []

    // MARK: - Public Methods

    /// Parse the `containedView`'s accessibility and add appropriate visual elements to represent it.
    ///
    /// This must be called _after_ the view is in the view hierarchy.
    ///
    /// - Throws: Throws a `RenderError` when the view fails to render a snapshot of the `containedView`.
    public func parseAccessibility() throws {
        // Clean up any previous markers.
        self.displayMarkers.forEach {
            $0.legendView.removeFromSuperview()
            $0.overlayView.removeFromSuperview()
            $0.activationPointView?.removeFromSuperview()
        }

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

        snapshotView.image = try containedView.renderToImage(
            monochrome: snapshotConfiguration.snapshot.colorMode == .monochrome,
            viewRenderingMode: snapshotConfiguration.snapshot.viewRenderingMode
        )
        snapshotView.bounds.size = containedView.bounds.size

        // Complete the layout pass after the view is restored to this container, in case it was modified during the
        // rendering process (i.e. when the rendering is tiled and stitched).
        containedView.layoutIfNeeded()

        let parser = AccessibilityHierarchyParser()
        let markers = parser.parseAccessibilityElements(in: containedView)

        var displayMarkers: [DisplayMarker] = []
        for (index, marker) in markers.enumerated() {
            let color = snapshotConfiguration.overlay.colors[index % snapshotConfiguration.overlay.colors.count]

            let legendView = LegendView(marker: marker, color: color, configuration: snapshotConfiguration.legend)
                                        elementIndex: elementIndex,
                                        color: color,
                                        showUserInputLabels: snapshotConfiguration.showUserInputLabels)
            addSubview(legendView)

            let overlayView = OverlayView()
            snapshotView.addSubview(overlayView)

            overlayView.markerView = {
                if let elementIndex {
                    return ElementMarkerView(color: color.withAlphaComponent(0.2), index: elementIndex, style: .pill)
                }
                return nil
            }()

            
            switch marker.shape {
            case let .frame(rect):
                // The `overlayView` itself is used to highlight the region.
                overlayView.backgroundColor = color.withAlphaComponent(0.3)
                overlayView.frame = rect
                if let elementIndex {
                    overlayView.markerView = ElementMarkerView(color: color.withAlphaComponent(0.2), index: elementIndex, style: .pill)
                    overlayView.markerPosition = .zero
                }

            case let .path(path):
                // The `overlayView` acts as a container for the highlight path. Since the `path` is already relative to
                // the `snapshotView`, the `overlayView` takes up the entire size of its parent.
                overlayView.frame = snapshotView.bounds
                let overlayLayer = CAShapeLayer()
                overlayLayer.lineWidth = 4
                overlayLayer.strokeColor = color.withAlphaComponent(0.3).cgColor
                overlayLayer.fillColor = nil
                overlayLayer.path = path.cgPath
                overlayView.layer.addSublayer(overlayLayer)
                if let elementIndex {
                    overlayView.markerView = ElementMarkerView(color: color.withAlphaComponent(0.2), index: elementIndex, style: .pill)
                    overlayView.markerPosition = overlayLayer.topLeadingPointOnPath(layoutDirection: .leftToRight) ?? .zero
                }
            }

            var displayMarker = DisplayMarker(
                marker: marker,
                legendView: legendView,
                overlayView: overlayView,
                activationPointView: nil
            )

            switch snapshotConfiguration.overlay.activationPointDisplay {
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
                activationPointView.tintColor = color
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

        var overlayView: OverlayView

        var activationPointView: UIView?

    }

}

internal extension AccessibilitySnapshotView {
    final class OverlayView : UIView {
        var markerPosition: CGPoint = .zero {
            didSet {
                guard let markerView else { return }
                markerView.sizeToFit()
                let origin = markerPosition
//                    .applying(CGAffineTransform(translationX: -(markerView.bounds.width / 2), y: -(markerView.bounds.height / 2 )))
                markerView.frame = CGRect(origin: origin, size: markerView.frame.size)
            }
        }
        
        var markerView: ElementMarkerView? {
            willSet {
                markerView?.removeFromSuperview()
            }
            didSet {
                if let markerView {
                    addSubview(markerView)
                }
            }
        }
    }
}

private extension UIView {

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


public extension CAShapeLayer {

    /// Returns the closest point *on this layer’s path* to the **top-leading** corner
    /// of the path’s bounding box.
    ///
    /// The result is expressed in `targetLayer` coordinates (defaults to `superlayer`),
    /// so you can position sibling layers or UI elements accurately even when this
    /// shape layer is transformed (position, bounds, `transform`, `sublayerTransform`, etc.).
    ///
    /// - Parameters:
    ///   - layoutDirection: `.leftToRight` (top-left) or `.rightToLeft` (top-right).
    ///   - curveSteps: Sampling resolution per curve segment (higher = more precise).
    ///                 Defaults to `32`; consider `64–128` for very tight curves.
    ///   - targetLayer: Coordinate space of the returned point. Default is `superlayer`.
    /// - Returns: The nearest point on the rendered path, in `targetLayer` coordinates, or `nil` if no path.
    @inlinable
    func topLeadingPointOnPath(
        layoutDirection: UIUserInterfaceLayoutDirection,
        curveSteps: Int = 32,
        targetLayer: CALayer? = nil
    ) -> CGPoint? {
        guard let path = self.path else { return nil }

        let target = targetLayer ?? self.superlayer
        let box = path.boundingBoxOfPath
        let cornerInSelf: CGPoint = (layoutDirection == .rightToLeft)
            ? CGPoint(x: box.maxX, y: box.minY) // top-right in iOS coords
            : CGPoint(x: box.minX, y: box.minY) // top-left in iOS coords

        // Convert corner into target coordinates (so we measure where it actually renders).
        let cornerInTarget = target != nil ? self.convert(cornerInSelf, to: target) : cornerInSelf

        var bestPointInTarget: CGPoint?
        var bestDist2 = CGFloat.greatestFiniteMagnitude

        // Track previous point of current subpath to build segments for projection.
        var p0 = CGPoint.zero
        var haveP0 = false

        // Project corner onto segment AB (in self coords), convert the projection to target space,
        // and keep the closest.
        @inline(__always)
        func considerSegment(_ a: CGPoint, _ b: CGPoint) {
            let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
            let ap = CGPoint(x: cornerInSelf.x - a.x, y: cornerInSelf.y - a.y)
            let abLen2 = ab.x*ab.x + ab.y*ab.y
            let t = abLen2 > 0 ? max(0, min(1, (ap.x*ab.x + ap.y*ab.y) / abLen2)) : 0
            let qSelf = CGPoint(x: a.x + t*ab.x, y: a.y + t*ab.y)

            let qTarget = target != nil ? self.convert(qSelf, to: target) : qSelf
            let dx = qTarget.x - cornerInTarget.x, dy = qTarget.y - cornerInTarget.y
            let d2 = dx*dx + dy*dy
            if d2 < bestDist2 { bestDist2 = d2; bestPointInTarget = qTarget }
        }

        @inline(__always)
        func quadPoint(_ p0: CGPoint, _ c: CGPoint, _ p1: CGPoint, _ t: CGFloat) -> CGPoint {
            let mt = 1 - t
            return CGPoint(
                x: mt*mt*p0.x + 2*mt*t*c.x + t*t*p1.x,
                y: mt*mt*p0.y + 2*mt*t*c.y + t*t*p1.y
            )
        }

        @inline(__always)
        func cubicPoint(_ p0: CGPoint, _ c1: CGPoint, _ c2: CGPoint, _ p1: CGPoint, _ t: CGFloat) -> CGPoint {
            let mt = 1 - t, mt2 = mt*mt, t2 = t*t
            return CGPoint(
                x: mt2*mt*p0.x + 3*mt2*t*c1.x + 3*mt*t2*c2.x + t*t2*p1.x,
                y: mt2*mt*p0.y + 3*mt2*t*c1.y + 3*mt*t2*c2.y + t*t2*p1.y
            )
        }

        path.applyWithBlock { el in
            let type = el.pointee.type
            let pts = el.pointee.points

            switch type {
            case .moveToPoint:
                p0 = pts[0]; haveP0 = true
                // Consider isolated points too (degenerate segment).
                considerSegment(p0, p0)

            case .addLineToPoint:
                if haveP0 {
                    let p1 = pts[0]
                    considerSegment(p0, p1)
                    p0 = p1
                }

            case .addQuadCurveToPoint:
                if haveP0 {
                    let c = pts[0], p1 = pts[1]
                    var prev = p0
                    let steps = max(1, curveSteps)
                    // Light sampling along the curve; each small chord is projected.
                    for i in 1...steps {
                        let t = CGFloat(i) / CGFloat(steps)
                        let pt = quadPoint(p0, c, p1, t)
                        considerSegment(prev, pt)
                        prev = pt
                    }
                    p0 = p1
                }

            case .addCurveToPoint:
                if haveP0 {
                    let c1 = pts[0], c2 = pts[1], p1 = pts[2]
                    var prev = p0
                    let steps = max(1, curveSteps)
                    for i in 1...steps {
                        let t = CGFloat(i) / CGFloat(steps)
                        let pt = cubicPoint(p0, c1, c2, p1, t)
                        considerSegment(prev, pt)
                        prev = pt
                    }
                    p0 = p1
                }

            case .closeSubpath:
                break

            @unknown default:
                break
            }
        }

        return bestPointInTarget
    }

    /// Convenience: infers layout direction from a `UIView`’s `semanticContentAttribute`,
    /// and returns the point in that view’s **layer** coordinate space.
    ///
    /// - Parameters:
    ///   - viewForLayoutDirection: The view whose semantic content attribute determines LTR/RTL.
    ///   - targetLayer: Optional custom layer space for the result. Defaults to `viewForLayoutDirection.layer`.
    ///   - curveSteps: Sampling resolution per curve segment.
    /// - Returns: The nearest point on the rendered path, in `targetLayer` coordinates.
    @inlinable
    func topLeadingPointOnPath(
        viewForLayoutDirection view: UIView,
        targetLayer: CALayer? = nil,
        curveSteps: Int = 32
    ) -> CGPoint? {
        let dir = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute)
        let space = targetLayer ?? view.layer
        return topLeadingPointOnPath(layoutDirection: dir, curveSteps: curveSteps, targetLayer: space)
    }
}

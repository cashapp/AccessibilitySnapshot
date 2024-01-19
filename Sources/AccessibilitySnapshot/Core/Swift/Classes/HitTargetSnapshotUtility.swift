//
//  Copyright 2024 Block Inc.
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

import CoreImage
import UIKit

public enum HitTargetSnapshotUtility {

    /// Generates an image of the provided `view` with hit target regions highlighted.
    ///
    /// The hit target regions are highlighted using the following rules:
    ///
    /// * Regions that hit test to the base view (`view`) will not be highlighted.
    /// * Regions that hit test to `nil` will be darkened.
    /// * Regions that hit test to another view will be highlighted using one of the specified `colors`.
    ///
    /// By default this snapshot is very slow (on the order of 50 seconds for a full screen snapshot) since it hit tests
    /// every pixel in the view to achieve a perfectly accurate result. As a performance optimization, you can trade off
    /// greatly increased performance for the possibility of missing very thin views by defining the maximum width and
    /// height of a region you are okay with missing (`maxPermissibleMissedRegion{Width,Height}`). In particular, this
    /// might miss hit regions of the specified width/height or less **which have the same hit target both above and
    /// below the region**. Note these are independent controls - a region could be missed if it falls beneath either of
    /// these thresholds, not both. Setting the either value alone to 1 pt improves the run time by almost (1 / scale
    /// factor), i.e. a 65% improvement for a 3x scale device, and setting both to 1 pt improves the run time by an
    /// additional (1 / scale factor), i.e. an ~88% improvement for a 3x scale device, so this trade-off is often worth
    /// it. Increasing the value from there will continue to decrease the run time, but you quickly get diminishing
    /// returns, so you likely won't ever want to go above 2-4 pt and should stick to 0 or 1 pt unless you have a large
    /// number of snapshots.
    ///
    /// - parameter view: The base view to be tested against.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views.
    /// - parameter viewRenderingMode: The rendering method to use when snapshotting the `view`.
    /// - parameter colors: An array of colors to use for the highlighted regions. These colors will be used in order,
    /// repeating through the array as necessary and avoiding adjacent regions using the same color when possible.
    /// - parameter maxPermissibleMissedRegionWidth: The maximum width for which it is permissible to "miss" a view.
    /// Value must be a positive integer.
    /// - parameter maxPermissibleMissedRegionHeight: The maximum height for which it is permissible to "miss" a view.
    /// Value must be a positive integer.
    public static func generateSnapshotImage(
        for view: UIView,
        useMonochromeSnapshot: Bool,
        viewRenderingMode: AccessibilitySnapshotView.ViewRenderingMode,
        colors: [UIColor] = AccessibilitySnapshotView.defaultMarkerColors,
        maxPermissibleMissedRegionWidth: CGFloat = 0,
        maxPermissibleMissedRegionHeight: CGFloat = 0
    ) throws -> (snapshot: UIImage, orderedViewColorPairs: [(UIColor, UIView)]) {
        let colors = colors.map { $0.withAlphaComponent(0.2) }

        let bounds = view.bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)

        let viewImage = try view.renderToImage(
            monochrome: useMonochromeSnapshot,
            viewRenderingMode: viewRenderingMode
        )

        guard view.bounds.width > 0 && view.bounds.height > 0 else {
            throw ImageRenderingError.containedViewHasZeroSize(viewSize: view.bounds.size)
        }

        var orderedViewColorPairs: [(UIColor, UIView)] = []

        let image = renderer.image { context in
            viewImage.draw(in: bounds)

            var viewToColorMap: [UIView: UIColor] = [:]
            let pixelWidth: CGFloat = 1 / UIScreen.main.scale

            let maxPermissibleMissedRegionWidth = max(pixelWidth, floor(maxPermissibleMissedRegionWidth))
            let maxPermissibleMissedRegionHeight = max(pixelWidth, floor(maxPermissibleMissedRegionHeight))

            func drawScanLineSegment(
                for hitView: UIView?,
                startingAtX: CGFloat,
                endingAtX: CGFloat,
                y: CGFloat,
                lineHeight: CGFloat
            ) {
                // Only draw hit areas for views other than the base view we're testing.
                guard hitView !== view else {
                    return
                }

                let color: UIColor
                if let hitView = hitView, let existingColor = viewToColorMap[hitView] {
                    color = existingColor
                } else if let hitView = hitView {
                    // As a future enhancement, this could be smarter about checking above/left colors to make sure they
                    // aren't the same.
                    color = colors[viewToColorMap.count % colors.count]
                    viewToColorMap[hitView] = color
                    orderedViewColorPairs.append((color, hitView))
                } else {
                    color = .lightGray
                }

                context.cgContext.setFillColor(color.cgColor)
                context.cgContext.beginPath()
                context.cgContext.addRect(
                    CGRect(
                        x: startingAtX,
                        y: y,
                        width: (endingAtX - startingAtX),
                        height: lineHeight
                    )
                )
                context.cgContext.drawPath(using: .fill)
            }

            let touchOffset = pixelWidth / 2

            typealias ScanLine = [(xRange: ClosedRange<CGFloat>, view: UIView?)]

            // In some cases striding by 1/3 can result in the `to` value being included due to a floating point rouding
            // error, in particular when dealing with bounds with a negative y origin. By striding to a value slightly
            // less than the desired stop (small enough to be less than the density of any screen in the foreseeable
            // future), we can avoid this rounding problem.
            let stopEpsilon: CGFloat = 0.0001

            func scanLine(y: CGFloat) -> ScanLine {
                var scanLine: ScanLine = []
                var lastHit: (CGFloat, UIView?) = (
                    bounds.minX,
                    view.hitTest(CGPoint(x: bounds.minX + touchOffset, y: y), with: nil)
                )

                func updateForHit(_ hitView: UIView?, at x: CGFloat) {
                    if hitView == lastHit.1 {
                        // We're still hitting the same view. Nothing to update.
                        return

                    } else {
                        // We've moved on to a new view, so draw the scan line for the previous view.
                        scanLine.append(((lastHit.0...x), lastHit.1))
                        lastHit = (x, hitView)

                    }
                }

                // Step through every pixel along the X axis.
                for x in stride(from: bounds.minX, to: bounds.maxX, by: maxPermissibleMissedRegionWidth) {
                    let hitView = view.hitTest(CGPoint(x: x + touchOffset, y: y), with: nil)

                    if hitView == lastHit.1 {
                        // We're still hitting the same view. Keep scanning.
                        continue

                    } else {
                        // The last iteration of the loop hit test at (x - maxPermissibleMissedRegionWidth), so we want
                        // to start one pixel in front of that.
                        let startX = x - maxPermissibleMissedRegionWidth + pixelWidth

                        for stepX in stride(from: startX, through: x, by: pixelWidth) {
                            let stepHitView = view.hitTest(CGPoint(x: stepX + touchOffset, y: y), with: nil)
                            updateForHit(stepHitView, at: stepX)
                        }
                    }
                }

                // Finish the scan line if necessary.
                if lastHit.0 != bounds.maxX {
                    scanLine.append(((lastHit.0...bounds.maxX), lastHit.1))
                }

                return scanLine
            }

            func drawScanLine(_ scanLine: ScanLine, y: CGFloat, lineHeight: CGFloat) {
                for segment in scanLine {
                    drawScanLineSegment(
                        for: segment.view,
                        startingAtX: segment.xRange.lowerBound,
                        endingAtX: segment.xRange.upperBound,
                        y: y,
                        lineHeight: lineHeight
                    )
                }
            }

            func scanLinesEqual(_ a: ScanLine, _ b: ScanLine) -> Bool {
                return a.count == b.count
                    && zip(a, b).allSatisfy { aSegment, bSegment in
                        aSegment.xRange == bSegment.xRange && aSegment.view === bSegment.view
                    }
            }

            // Step through every full point along the Y axis and check if it's equal to the above line. If so, draw the
            // line at a full point width. If not, step through the pixel lines and draw each individually.
            var previousScanLine: (y: CGFloat, scanLine: ScanLine)? = nil
            for y in stride(from: bounds.minY, to: bounds.maxY, by: maxPermissibleMissedRegionHeight) {
                let fullScanLine = scanLine(y: y + touchOffset)

                if let previousScanLine = previousScanLine, scanLinesEqual(fullScanLine, previousScanLine.scanLine) {
                    drawScanLine(
                        previousScanLine.scanLine,
                        y: previousScanLine.y,
                        lineHeight: maxPermissibleMissedRegionHeight
                    )

                } else if let previousScanLine = previousScanLine {
                    drawScanLine(previousScanLine.scanLine, y: previousScanLine.y, lineHeight: pixelWidth)
                    for lineY in stride(from: previousScanLine.y + pixelWidth, to: y - stopEpsilon, by: pixelWidth) {
                        drawScanLine(scanLine(y: lineY + touchOffset), y: lineY, lineHeight: pixelWidth)
                    }

                } else {
                    // No-op. We'll draw this on the next iteration.
                }

                previousScanLine = (y, fullScanLine)
            }

            // Draw the final full scan line and any trailing pixel lines (if the bounds.height isn't divisible by the
            // maxPermissibleMissedRegionHeight).
            if let previousScanLine = previousScanLine {
                drawScanLine(previousScanLine.scanLine, y: previousScanLine.y, lineHeight: pixelWidth)

                for lineY in stride(from: previousScanLine.y + pixelWidth, to: bounds.maxY, by: pixelWidth) {
                    drawScanLine(scanLine(y: lineY + touchOffset), y: lineY, lineHeight: pixelWidth)
                }
            }
        }

        return (image, orderedViewColorPairs)
    }

}

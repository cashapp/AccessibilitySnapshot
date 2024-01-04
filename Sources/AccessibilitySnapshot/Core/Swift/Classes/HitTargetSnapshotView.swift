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
    /// - parameter view: The base view to be tested against.
    /// - parameter useMonochromeSnapshot: Whether or not the snapshot of the `view` should be monochrome. Using a
    /// monochrome snapshot makes it more clear where the highlighted elements are, but may make it difficult to
    /// read certain views.
    /// - parameter viewRenderingMode: The rendering method to use when snapshotting the `view`.
    /// - parameter colors: An array of colors to use for the highlighted regions. These colors will be used in order,
    /// repeating through the array as necessary and avoiding adjacent regions using the same color when possible.
    public static func generateSnapshotImage(
        for view: UIView,
        useMonochromeSnapshot: Bool,
        viewRenderingMode: AccessibilitySnapshotView.ViewRenderingMode,
        colors: [UIColor] = AccessibilitySnapshotView.defaultMarkerColors
    ) throws -> UIImage {
        let colors = colors.map { $0.withAlphaComponent(0.2) }

        let bounds = view.bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)

        let viewImage = try view.renderToImage(
            monochrome: useMonochromeSnapshot,
            viewRenderingMode: viewRenderingMode
        )

        return renderer.image { context in
            viewImage.draw(in: bounds)

            var viewToColorMap: [UIView: UIColor] = [:]
            let pixelWidth: CGFloat = 1 / UIScreen.main.scale

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

            func scanLine(y: CGFloat) -> ScanLine {
                var scanLine: ScanLine = []
                var lastHit: (CGFloat, UIView?)? = nil

                // Step through every pixel along the X axis.
                for x in stride(from: bounds.minX, to: bounds.maxX, by: pixelWidth) {
                    let hitView = view.hitTest(CGPoint(x: x + touchOffset, y: y), with: nil)

                    if let lastHit = lastHit, hitView == lastHit.1 {
                        // We're still hitting the same view. Keep scanning.
                        continue

                    } else if let previousHit = lastHit {
                        // We've moved on to a new view, so draw the scan line for the previous view.
                        scanLine.append(((previousHit.0...x), previousHit.1))
                        lastHit = (x, hitView)

                    } else {
                        // We've started a new view's region.
                        lastHit = (x, hitView)
                    }
                }

                // Finish the scan line if necessary.
                if let lastHit = lastHit, let lastHitView = lastHit.1 {
                    scanLine.append(((lastHit.0...bounds.maxX), lastHitView))
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

            // Step through every pixel along the Y axis.
            for y in stride(from: bounds.minY, to: bounds.maxY, by: pixelWidth) {
                let scanLine = scanLine(y: y + touchOffset)
                drawScanLine(scanLine, y: y, lineHeight: pixelWidth)
            }
        }
    }

}

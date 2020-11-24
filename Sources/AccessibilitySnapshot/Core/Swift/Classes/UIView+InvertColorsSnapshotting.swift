//
//  Copyright 2019 Square Inc.
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

import CoreGraphics
import CoreImage
import UIKit

extension UIView {

    // MARK: - Public Methods

    public func drawHierarchyWithInvertedColors(in rect: CGRect, using context: UIGraphicsImageRendererContext) {
        if accessibilityIgnoresInvertColors {
            drawHierarchy(in: rect, afterScreenUpdates: false)

        } else {
            let subviewsToDrawSeparately = subviews.filter { subview in
                !subview.isHidden && subview.hasSubviewInHierarchyThatIgnoresInvertColors
            }
            subviewsToDrawSeparately.forEach { $0.isHidden = true }
            CATransaction.flush()

            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            let image = renderer.image { context in
                drawHierarchy(in: bounds, afterScreenUpdates: false)
            }

            let filter = CIFilter(name: "CIColorInvert")!
            filter.setValue(image.ciImage ?? CIImage(cgImage: image.cgImage!), forKey: kCIInputImageKey)
            let ciContext = CIContext(cgContext: context.cgContext, options: nil)
            let invertedCIImage = filter.outputImage!
            let invertedCGImage = ciContext.createCGImage(invertedCIImage, from: invertedCIImage.extent)!

            context.cgContext.draw(invertedCGImage, in: rect)

            subviewsToDrawSeparately.forEach { $0.isHidden = false }
            CATransaction.flush()

            // Sort the visible subviews by their ordering in the draw stack. For the most part, the
            // position of views is determined by the ordering of `subviews`, with the exception of those
            // for which their layer's `zPosition` has been changed. Since `Sequence.sorted(by:)` doesn't
            // guarantee a stable sort, this sorts an enumerated copy of the sequence so it has stable
            // indices.
            let orderedSubviewsToDraw = subviewsToDrawSeparately
                .enumerated()
                .sorted { enumeratedSubview1, enumeratedSubview2 in
                    let (index1, subview1) = enumeratedSubview1
                    let (index2, subview2) = enumeratedSubview2

                    if subview1.layer.zPosition < subview2.layer.zPosition {
                        return true
                    } else if subview1.layer.zPosition > subview2.layer.zPosition {
                        return false
                    } else {
                        return index1 < index2
                    }
                }
                .map { $0.1 }

            for subview in orderedSubviewsToDraw {
                subview.drawHierarchyWithInvertedColors(
                    in: .init(
                        x: rect.origin.x + subview.frame.origin.x,
                        y: rect.origin.y + subview.frame.origin.y,
                        width: subview.frame.width,
                        height: subview.frame.height
                    ),
                    using: context
                )
            }
        }
    }

    // MARK: - Private Properties

    private var hasSubviewInHierarchyThatIgnoresInvertColors: Bool {
        if accessibilityIgnoresInvertColors {
            return true
        }

        return subviews.contains { $0.hasSubviewInHierarchyThatIgnoresInvertColors }
    }

}

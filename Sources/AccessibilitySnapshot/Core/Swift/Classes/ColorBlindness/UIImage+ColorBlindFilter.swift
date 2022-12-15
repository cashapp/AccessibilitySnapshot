//
//  Copyright 2022 Square Inc.
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

extension UIImage {

    public func applyColorBlindFilter(_ colorBlindnessType: ColorBlindnessType) -> UIImage? {
        let matrix = colorBlindnessType.createMatrix()

        guard let imageRef = cgImage else {
            return nil
        }

        let width = imageRef.width
        let height = imageRef.height

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapByteCount = bytesPerRow * height

        var rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)

        defer {
            rawData.deallocate()
        }

        guard let context = CGContext(
            data: rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpace(name: CGColorSpace.genericRGBLinear)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            // This should never actually happen.
            return nil
        }

        // Draw the image into our CoreGraphics context
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(imageRef, in: rect)

        // The current byte which we're looking at, updated with each cycle
        var byteIndex = 0

        while byteIndex < bitmapByteCount {
            // Update the pixel in the rawData, performing the matrix transformation
            matrix.updatePixel(data: &rawData, byteIndex: byteIndex)

            // Loop to the next pixel (4 bytes per pixel for RGBA)
            byteIndex += 4
        }

        // Retrieve the image from the in-memory context
        return context.makeImage().map(UIImage.init(cgImage:))
    }

}

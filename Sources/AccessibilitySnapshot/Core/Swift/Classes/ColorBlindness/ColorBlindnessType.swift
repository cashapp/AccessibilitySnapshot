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

import Foundation

public enum ColorBlindnessType: String, CaseIterable {

    /// Color blindness to red.
    case protanopia

    /// Reduced sensitivity to red.
    case protanomaly

    /// Color blindness to green.
    case deuteranopia

    /// Reduced sensitivity to green.
    case deuteranomaly

    /// Color blindness to blue.
    case tritanopia

    /// Reduced sensitivity to blue.
    case tritanomaly

    /// Monochromacy (total color blindness).
    case achromatopsia

    /// Reduced sensitivity to all colors.
    case achromatomaly

    /// Create a RGBA filter matrix for the different color blindness simulations.
    internal func createMatrix() -> ImageFilterMatrix {
        switch self {
        case .protanopia:
            return ImageFilterMatrix(
                red:   [ 0.567, 0.433, 0,     0, 0 ],
                green: [ 0.558, 0.442, 0,     0, 0 ],
                blue:  [ 0,     0.242, 0.758, 0, 0 ],
                alpha: [ 0,     0,     0,     1, 0 ]
            )

        case .protanomaly:
            return ImageFilterMatrix(
                red:   [ 0.817, 0.183, 0,     0, 0 ],
                green: [ 0.333, 0.667, 0,     0, 0 ],
                blue:  [ 0,     0.125, 0.875, 0, 0 ],
                alpha: [ 0,     0,     0,     1, 0 ]
            )

        case .deuteranopia:
            return ImageFilterMatrix(
                red:   [ 0.625, 0.375, 0,     0, 0 ],
                green: [ 0.7,   0.3,   0,     0, 0 ],
                blue:  [ 0,     0.3,   0.7,   0, 0 ],
                alpha: [ 0,     0,     0,     1, 0 ]
            )

        case .deuteranomaly:
            return ImageFilterMatrix(
                red:   [ 0.8,   0.2,   0,     0, 0 ],
                green: [ 0.258, 0.742, 0,     0, 0 ],
                blue:  [ 0,     0.142, 0.858, 0, 0 ],
                alpha: [ 0,     0,     0,     1, 0 ]
            )

        case .tritanopia:
            return ImageFilterMatrix(
                red:   [ 0.95,  0.05,  0,     0, 0 ],
                green: [ 0,     0.433, 0.567, 0, 0 ],
                blue:  [ 0,     0.475, 0.525, 0, 0 ],
                alpha: [ 0,     0,     0,     1, 0 ]
            )

        case .tritanomaly:
            return ImageFilterMatrix(
                red:   [ 0.967, 0.033, 0,     0, 0 ],
                green: [ 0,     0.733, 0.267, 0, 0 ],
                blue:  [ 0,     0.183, 0.817, 0, 0 ],
                alpha: [ 0,     0,     0,     1, 0 ]
            )

        case .achromatopsia:
            return ImageFilterMatrix(
                red:   [ 0.299, 0.587, 0.144, 0, 0 ],
                green: [ 0.299, 0.587, 0.144, 0, 0 ],
                blue:  [ 0.299, 0.587, 0.144, 0, 0 ],
                alpha: [ 0,     0,     0,     1, 0 ]
            )

        case .achromatomaly:
            return ImageFilterMatrix(
                red:   [ 0.618, 0.320, 0.062, 0, 0 ],
                green: [ 0.163, 0.775, 0.062, 0, 0 ],
                blue:  [ 0.163, 0.320, 0.516, 0, 0 ],
                alpha: [ 0,     0,     0,     1, 0 ]
            )
        }
    }

}

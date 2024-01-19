//
//  Copyright 2021 Square Inc.
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

#if SWIFT_PACKAGE || BAZEL_PACKAGE
import AccessibilitySnapshotCore
#endif

internal enum ErrorMessageFactory {

    static var errorMessageForMissingHostApplication: String {
        return "Accessibility snapshot tests cannot be run in a test target without a host application"
    }

    static func errorMessageForAccessibilityParsingError(_ error: Error) -> String {
        switch error {
        case ImageRenderingError.containedViewExceedsMaximumSize:
            return """
                View is too large to render monochrome snapshot. Try setting useMonochromeSnapshot to false or use a \
                different iOS version. In particular, this is known to fail on iOS 13, but was fixed in iOS 14.
                """
        case ImageRenderingError.containedViewHasUnsupportedTransform:
            return """
                View has an unsupported transform for the specified snapshot parameters. Try using an identity \
                transform or changing the view rendering mode to render the layer in the graphics context.
                """
        default:
            return "Failed to render snapshot image"
        }
    }

}

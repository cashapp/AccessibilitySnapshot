import AccessibilitySnapshotCore
import Foundation

enum ErrorMessageFactory {
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

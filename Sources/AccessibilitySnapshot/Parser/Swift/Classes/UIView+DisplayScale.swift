import UIKit

public extension UIView {
    /// The scale factor of the display the view is rendered on.
    ///
    /// This reads the scale from the view's trait environment rather than from `UIScreen`, which is unavailable on
    /// visionOS. Views that aren't installed in a window may report a display scale of `0`, in which case this falls
    /// back to an unscaled (`1`) value.
    var effectiveDisplayScale: CGFloat {
        let displayScale = traitCollection.displayScale
        return displayScale > 0 ? displayScale : 1
    }
}

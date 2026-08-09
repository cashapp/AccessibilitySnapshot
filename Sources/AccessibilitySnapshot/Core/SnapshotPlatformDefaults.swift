import UIKit

/// Platform-specific defaults used when no explicit size is provided for a snapshot.
///
/// On iOS these fall back to the main screen's bounds. `UIScreen` is unavailable on visionOS, where windows aren't
/// backed by a screen at all, so an explicit default window size is used there instead.
public enum SnapshotPlatformDefaults {
    /// The frame to use for a host window when there is no existing key window to install a view in.
    public static var hostWindowFrame: CGRect {
        #if os(visionOS)
        // The default size visionOS gives a plain window, in points.
        return CGRect(origin: .zero, size: CGSize(width: 1280, height: 720))
        #else
        return UIScreen.main.bounds
        #endif
    }

    /// The size to use when rendering a view for which no explicit render size was specified.
    public static var renderSize: CGSize {
        return hostWindowFrame.size
    }
}

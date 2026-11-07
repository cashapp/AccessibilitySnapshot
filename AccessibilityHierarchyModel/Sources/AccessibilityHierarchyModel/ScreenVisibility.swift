/// Whether an element is on screen.
///
/// The parser sets this from scroll clipping, which needs UIKit context. Consumers with more context,
/// such as the screen bounds of a running app, can update it.
public enum ScreenVisibility: String, Hashable, Codable, Sendable {
    /// The element's visible frame intersects the visible region of every scrollable ancestor.
    case onscreen

    /// The element is clipped out by a scrollable ancestor (or an off-screen ancestor).
    case offscreen
}

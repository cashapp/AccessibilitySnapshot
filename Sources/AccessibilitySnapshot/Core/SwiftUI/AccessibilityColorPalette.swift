import SwiftUI
import UIKit

/// A configurable color palette for accessibility preview rendering.
public struct AccessibilityColorPalette {
    public let colors: [UIColor]
    public let fillOpacity: CGFloat
    public let strokeOpacity: CGFloat

    public init(
        colors: [UIColor],
        fillOpacity: CGFloat = 0.25,
        strokeOpacity: CGFloat = 0.8
    ) {
        self.colors = colors
        self.fillOpacity = fillOpacity
        self.strokeOpacity = strokeOpacity
    }

    /// Returns the base color at the given index (wraps around).
    public func color(at index: Int) -> UIColor {
        colors[index % colors.count]
    }

    /// Returns the fill color (with fill opacity) at the given index.
    public func fillColor(at index: Int) -> Color {
        Color(color(at: index)).opacity(fillOpacity)
    }

    /// Returns the stroke color (with stroke opacity) at the given index.
    public func strokeColor(at index: Int) -> Color {
        Color(color(at: index)).opacity(strokeOpacity)
    }

    /// Returns the full opacity color at the given index (for text/badges).
    public func solidColor(at index: Int) -> Color {
        Color(color(at: index))
    }

    /// Default 14-color palette from design.
    public static let `default` = AccessibilityColorPalette(colors: [
        UIColor(red: 0x69 / 255.0, green: 0x29 / 255.0, blue: 0xC4 / 255.0, alpha: 1), // #6929C4 Purple
        UIColor(red: 0x11 / 255.0, green: 0x92 / 255.0, blue: 0xE8 / 255.0, alpha: 1), // #1192E8 Blue
        UIColor(red: 0x00 / 255.0, green: 0x5D / 255.0, blue: 0x5D / 255.0, alpha: 1), // #005D5D Dark Teal
        UIColor(red: 0x9F / 255.0, green: 0x18 / 255.0, blue: 0x53 / 255.0, alpha: 1), // #9F1853 Magenta
        UIColor(red: 0xFA / 255.0, green: 0x4D / 255.0, blue: 0x56 / 255.0, alpha: 1), // #FA4D56 Red/Coral
        UIColor(red: 0x57 / 255.0, green: 0x04 / 255.0, blue: 0x08 / 255.0, alpha: 1), // #570408 Dark Red
        UIColor(red: 0x19 / 255.0, green: 0x80 / 255.0, blue: 0x38 / 255.0, alpha: 1), // #198038 Green
        UIColor(red: 0x00 / 255.0, green: 0x2D / 255.0, blue: 0x9C / 255.0, alpha: 1), // #002D9C Dark Blue
        UIColor(red: 0xEE / 255.0, green: 0x53 / 255.0, blue: 0x8B / 255.0, alpha: 1), // #EE538B Pink
        UIColor(red: 0xB2 / 255.0, green: 0x86 / 255.0, blue: 0x00 / 255.0, alpha: 1), // #B28600 Gold
        UIColor(red: 0x00 / 255.0, green: 0x9D / 255.0, blue: 0x9A / 255.0, alpha: 1), // #009D9A Cyan
        UIColor(red: 0x01 / 255.0, green: 0x27 / 255.0, blue: 0x49 / 255.0, alpha: 1), // #012749 Navy
        UIColor(red: 0x8A / 255.0, green: 0x38 / 255.0, blue: 0x00 / 255.0, alpha: 1), // #8A3800 Brown/Orange
        UIColor(red: 0xA5 / 255.0, green: 0x6E / 255.0, blue: 0xFF / 255.0, alpha: 1), // #A56EFF Light Purple
    ])
}

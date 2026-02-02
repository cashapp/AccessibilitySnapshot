import SwiftUI
import UIKit

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1
        )
    }
}

public struct ColorPalette {
    private let colors: [UIColor]
    public let fillOpacity: CGFloat
    public let strokeOpacity: CGFloat

    public init?(
        colors: [UIColor],
        fillOpacity: CGFloat = 0.3,
        strokeOpacity: CGFloat = 0.3
    ) {
        guard !colors.isEmpty else { return nil }
        self.colors = colors
        self.fillOpacity = fillOpacity
        self.strokeOpacity = strokeOpacity
    }

    private init(
        uncheckedColors colors: [UIColor],
        fillOpacity: CGFloat,
        strokeOpacity: CGFloat
    ) {
        self.colors = colors
        self.fillOpacity = fillOpacity
        self.strokeOpacity = strokeOpacity
    }

    public func color(at index: Int) -> UIColor {
        colors[index % colors.count]
    }

    public func color(at index: Int) -> Color {
        Color(colors[index % colors.count])
    }

    public func fillColor(at index: Int) -> UIColor {
        color(at: index).withAlphaComponent(fillOpacity)
    }

    public func strokeColor(at index: Int) -> UIColor {
        color(at: index).withAlphaComponent(strokeOpacity)
    }

    public func fillColor(at index: Int) -> Color {
        Color(color(at: index)).opacity(fillOpacity)
    }

    public func strokeColor(at index: Int) -> Color {
        Color(color(at: index)).opacity(strokeOpacity)
    }

    // MARK: - Presets

    public static let legacy = ColorPalette(
        uncheckedColors: MarkerColors.defaultColors,
        fillOpacity: 0.3,
        strokeOpacity: 0.3
    )

    public static let modern = ColorPalette(
        uncheckedColors: [
            UIColor(hex: 0x6929C4),
            UIColor(hex: 0x1192E8),
            UIColor(hex: 0x005D5D),
            UIColor(hex: 0x9F1853),
            UIColor(hex: 0xFA4D56),
            UIColor(hex: 0x570408),
            UIColor(hex: 0x198038),
            UIColor(hex: 0x002D9C),
            UIColor(hex: 0xEE538B),
            UIColor(hex: 0xB28600),
            UIColor(hex: 0x009D9A),
            UIColor(hex: 0x012749),
            UIColor(hex: 0x8A3800),
        ],
        fillOpacity: 0.25,
        strokeOpacity: 0.8
    )

    public static let `default` = modern
}

public extension ColorPalette {
    init(legacyColors: [UIColor]) {
        guard let palette = Self(colors: legacyColors,
                                 fillOpacity: 0.3,
                                 strokeOpacity: 0.3) else {
            self = .legacy
            return
        }
        self = palette
    }

    init(modernColors: [UIColor]) {
        guard let palette = Self(colors: modernColors,
                                 fillOpacity: 0.25,
                                 strokeOpacity: 0.8) else {
            self = .modern
            return
        }
        self = palette
    }
}

public typealias AccessibilityColorPalette = ColorPalette

// MARK: - Legacy Support

/// The original color palette type used before `ColorPalette` was introduced.
@available(*, deprecated, message: "Use ColorPalette.legacy instead")
public enum MarkerColors {
    @available(*, deprecated, message: "Use ColorPalette.legacy instead")
    public static let defaultColors: [UIColor] = [.cyan, .magenta, .green, .blue, .yellow, .purple, .orange]
}

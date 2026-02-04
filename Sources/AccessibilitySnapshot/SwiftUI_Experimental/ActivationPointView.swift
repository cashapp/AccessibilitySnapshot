import AccessibilitySnapshotParser
import SwiftUI

/// Displays an activation point crosshairs indicator.
@available(iOS 16.0, *)
public struct ActivationPointView: View {
    public let position: CGPoint
    public let color: Color

    public init(position: CGPoint, color: Color) {
        self.position = position
        self.color = color
    }

    public var body: some View {
        Image("Crosshairs", bundle: .accessibilitySnapshotResources)
            .resizable()
            .frame(width: DesignTokens.ActivationPoint.size, height: DesignTokens.ActivationPoint.size)
            .foregroundColor(color)
            .position(position)
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        ActivationPointView(position: CGPoint(x: 100, y: 100), color: .red)
    }
    .frame(width: 200, height: 200)
}

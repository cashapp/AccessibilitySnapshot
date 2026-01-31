import AccessibilitySnapshotParser
import SwiftUI

/// Displays an activation point crosshairs indicator.
struct ActivationPointView: View {
    let position: CGPoint
    let color: Color

    private enum Metrics {
        static let size: CGFloat = 16
    }

    var body: some View {
        Image("Crosshairs", bundle: .accessibilitySnapshotResources)
            .resizable()
            .frame(width: Metrics.size, height: Metrics.size)
            .foregroundColor(color)
            .position(position)
    }
}

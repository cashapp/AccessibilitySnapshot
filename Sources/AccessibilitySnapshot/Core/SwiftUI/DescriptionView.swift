import SwiftUI

/// Displays an accessibility element's description.
struct DescriptionView: View {
    let text: String

    private enum Metrics {
        static let font = Font.system(size: LegendLayoutMetrics.descriptionFontSize)
    }

    var body: some View {
        Text(text)
            .font(Metrics.font)
            .foregroundColor(.black)
    }
}

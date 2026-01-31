import SwiftUI

/// Displays an accessibility element's hint.
struct HintView: View {
    let text: String

    private enum Metrics {
        static let font = Font.system(size: LegendLayoutMetrics.hintFontSize).italic()
        static let color = Color(white: 0.4)
    }

    var body: some View {
        Text(text)
            .font(Metrics.font)
            .foregroundColor(Metrics.color)
    }
}

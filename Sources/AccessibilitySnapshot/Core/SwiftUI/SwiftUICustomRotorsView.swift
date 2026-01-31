import AccessibilitySnapshotParser
import SwiftUI
import UIKit

/// Displays an element's custom rotors (SwiftUI version).
struct SwiftUICustomRotorsView: View {
    let rotors: [AccessibilityMarker.CustomRotor]
    let locale: String?

    private enum Metrics {
        static let verticalSpacing: CGFloat = 2
        static let indent: CGFloat = 12
        static let font = Font.system(size: 12)
        static let boldFont = Font.system(size: 12, weight: .bold)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.verticalSpacing) {
            ForEach(rotors.indices, id: \.self) { index in
                let rotor = rotors[index]

                Text("↺ \(rotor.name):")
                    .font(Metrics.boldFont)
                    .foregroundColor(.black)

                Text(resultsText(for: rotor))
                    .font(Metrics.font)
                    .foregroundColor(.black)
                    .padding(.leading, Metrics.indent)
            }
        }
    }

    private func resultsText(for rotor: AccessibilityMarker.CustomRotor) -> String {
        guard !rotor.resultMarkers.isEmpty else {
            return Strings.noResultsText(for: locale)
        }

        let resultsString = rotor.resultMarkers.map { "- \($0.elementDescription)" }.joined(separator: "\n")

        switch rotor.limit {
        case .none:
            return resultsString
        case let .underMaxCount(count):
            return resultsString + "\n" + Strings.moreResultsText(count: count, for: locale)
        case .greaterThanMaxCount:
            return resultsString + "\n" + Strings.maxLimitText(max: UIAccessibilityCustomRotor.CollectedRotorResults.maximumCount, for: locale)
        }
    }
}

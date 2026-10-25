import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI
import UIKit

/// Displays an element's custom rotors.
@available(iOS 16.0, *)
struct CustomRotorsView: View {
    let rotors: [AccessibilityMarker.CustomRotor]
    let locale: String?

    private typealias Tokens = DesignTokens.CustomContent

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.verticalSpacing) {
            ForEach(rotors.indices, id: \.self) { index in
                let rotor = rotors[index]

                Text("↺ \(rotor.name):")
                    .font(DesignTokens.Typography.secondaryBold)
                    .foregroundColor(DesignTokens.Colors.primaryText)
                    .lineLimit(nil)

                Text(resultsText(for: rotor))
                    .font(DesignTokens.Typography.secondary)
                    .foregroundColor(DesignTokens.Colors.primaryText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, Tokens.indent)
            }
        }
    }

    private func resultsText(for rotor: AccessibilityMarker.CustomRotor) -> String {
        guard !rotor.results.isEmpty else {
            return Strings.noResultsText(for: locale)
        }

        let resultsString = rotor.results.map { "- \($0.elementDescription)" }.joined(separator: "\n")

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

// MARK: - Preview

@available(iOS 16.0, *)
#Preview("Single Rotor") {
    CustomRotorsView(
        rotors: [
            .init(
                name: "Headings",
                results: [
                    .init(elementDescription: "Welcome"),
                    .init(elementDescription: "Features"),
                    .init(elementDescription: "Pricing"),
                ]
            ),
        ],
        locale: nil
    )
    .padding()
}

@available(iOS 16.0, *)
#Preview("Multiple Rotors") {
    CustomRotorsView(
        rotors: [
            .init(
                name: "Headings",
                results: [
                    .init(elementDescription: "Welcome"),
                    .init(elementDescription: "Features"),
                ]
            ),
            .init(
                name: "Links",
                results: [
                    .init(elementDescription: "Learn more"),
                    .init(elementDescription: "Contact us"),
                ]
            ),
        ],
        locale: nil
    )
    .padding()
}

@available(iOS 16.0, *)
#Preview("Empty Rotor") {
    CustomRotorsView(
        rotors: [
            .init(name: "Headings", results: []),
        ],
        locale: nil
    )
    .padding()
}

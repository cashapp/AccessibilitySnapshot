import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// A complete legend entry for one accessibility element.
@available(iOS 16.0, *)
struct LegendEntryView: View {
    let index: Int
    let marker: AccessibilityMarker
    let palette: ColorPalette
    let showUserInputLabels: Bool
    let showUnspokenTraits: Bool

    var body: some View {
        HStack(alignment: .top, spacing: LegendLayoutMetrics.markerToLabelSpacing) {
            ElementView(
                index: index,
                palette: palette,
                mode: .legend
            )

            VStack(alignment: .leading, spacing: LegendLayoutMetrics.interItemSpacing) {
                DescriptionView(text: marker.description)

                if let hint = marker.hint {
                    HintView(text: hint)
                }

                if showUnspokenTraits {
                    TraitsView(traits: marker.traits)
                }

                if !marker.customContent.isEmpty {
                    CustomContentView(
                        content: marker.customContent,
                        locale: marker.accessibilityLanguage
                    )
                }

                if !marker.customActions.isEmpty {
                    CustomActionsView(
                        actions: marker.customActions,
                        locale: marker.accessibilityLanguage
                    )
                }

                let displayRotors = marker.customRotors.filter { !$0.resultMarkers.isEmpty }
                if !displayRotors.isEmpty {
                    CustomRotorsView(
                        rotors: displayRotors,
                        locale: marker.accessibilityLanguage
                    )
                }

                if showUserInputLabels, let labels = marker.userInputLabels, !labels.isEmpty {
                    UserInputLabelsView(labels: labels)
                }
            }
        }
    }
}

@_spi(Rendering) import AccessibilitySnapshotCore
import AccessibilitySnapshotParser
import SwiftUI

/// A complete legend entry for one accessibility element.
@available(iOS 16.0, *)
struct LegendEntryView: View {
    let index: Int
    let marker: AccessibilityMarker
    let palette: ColorPalette
    let configuration: AccessibilitySnapshotConfiguration

    var userInputLabels: [String] {
        marker.displayInputLabels(configuration.inputLabelDisplayMode)
    }

    var body: some View {
        HStack(alignment: .top, spacing: LegendLayoutMetrics.markerToLabelSpacing) {
            NumberBadge(index: index, palette: palette)

            VStack(alignment: .leading, spacing: LegendLayoutMetrics.interItemSpacing) {
                DescriptionView(text: marker.description)

                if let hint = marker.hint {
                    HintView(text: hint)
                }

                if configuration.showsUnspokenTraits {
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

                if !userInputLabels.isEmpty {
                    UserInputLabelsView(labels: userInputLabels)
                }
            }
        }
    }
}

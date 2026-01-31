import AccessibilitySnapshotParser
import SwiftUI

/// A complete legend entry for one accessibility element.
struct LegendEntryView: View {
    let index: Int
    let marker: AccessibilityMarker
    let palette: AccessibilityColorPalette
    let showUserInputLabels: Bool

    var body: some View {
        HStack(alignment: .top, spacing: LegendLayoutMetrics.markerToLabelSpacing) {
            ElementView(
                index: index,
                palette: palette,
                mode: .legend
            )

            VStack(alignment: .leading, spacing: LegendLayoutMetrics.interSectionSpacing) {
                DescriptionView(text: marker.description)

                if let hint = marker.hint {
                    HintView(text: hint)
                }

                if !marker.customContent.isEmpty {
                    SwiftUICustomContentView(
                        content: marker.customContent,
                        locale: marker.accessibilityLanguage
                    )
                }

                if !marker.customActions.isEmpty {
                    SwiftUICustomActionsView(
                        actions: marker.customActions,
                        locale: marker.accessibilityLanguage
                    )
                }

                let displayRotors = marker.customRotors.filter { !$0.resultMarkers.isEmpty }
                if !displayRotors.isEmpty {
                    SwiftUICustomRotorsView(
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

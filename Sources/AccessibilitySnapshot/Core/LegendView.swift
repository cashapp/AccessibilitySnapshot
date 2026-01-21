import UIKit
import AccessibilitySnapshotParser

internal extension AccessibilitySnapshotView {
    final class LegendView: UIView {

        // MARK: - Life Cycle
        
        init(marker: AccessibilityMarker, color: UIColor, configuration: AccessibilitySnapshotConfiguration) {
            self.hintLabel = marker.hint.map {
                let label = UILabel()
                label.text = $0
                label.font = Metrics.hintLabelFont
                label.textColor = .init(white: 0.3, alpha: 1.0)
                label.numberOfLines = 0
                return label
            }

            // If our description and hint are both empty, but we have custom actions, we'll use the description label
            // to show the "Actions Available" text, since this makes our layout simpler when we align to the marker.
            let showActionsAvailableInDescription = (marker.description.isEmpty && !marker.customActions.isEmpty)

            self.customActionsView = {
                guard !marker.customActions.isEmpty else { return nil }
                
                return .init(
                    actionsAvailableText: showActionsAvailableInDescription
                        ? nil
                        : Strings.actionsAvailableText(for: marker.accessibilityLanguage),
                    customActions: marker.customActions
                )
            }()
            
            // If our description and hint are both empty, and we don't have custom actions, but we do have custom content, we'll use the description label
            // to show the "Custom Content Available" text, since this makes our layout simpler when we align to the marker.
            let showCustomContentInDescription = (marker.description.isEmpty &&
                                                  !showActionsAvailableInDescription &&
                                                  !marker.customContent.isEmpty)

            self.customContentView = {
                guard !marker.customContent.isEmpty else { return nil }
                
                return .init(
                    customContentText: showCustomContentInDescription
                        ? nil
                        : Strings.moreContentAvailableText(for: marker.accessibilityLanguage),
                    customContent: marker.customContent
                )
            }()

            let rotors = marker.displayRotors(configuration.rotors.displayMode)
            self.customRotorsView = rotors.isEmpty ? nil : .init(
                    rotors: rotors,
                    locale: marker.accessibilityLanguage
                )
            
            self.userInputLabelsView = {
    
               let userInputLabels: [String]? = {
                   
                   switch configuration.inputLabelDisplayMode {
                   case .always:
                       guard let labels = marker.userInputLabels, !labels.isEmpty else {
                           /// If no labels are provided the accessibility label will be used, split on spaces.
                           var labels = marker.label?.split(separator: " ").map(String.init) ?? []
                           
                           /// The button trait precedes the adjustable trait if both are present.
                           if  marker.traits.contains(.button) {
                               labels.append(Strings.buttonInputLabelText(for: marker.accessibilityLanguage))
                           }
                           if marker.traits.contains(.adjustable) {
                               labels.append(Strings.adjustableInputLabelText(for: marker.accessibilityLanguage))
                           }
                           
                           return labels
                       }
                       return marker.userInputLabels
                       
                   case .whenOverridden:
                       guard
                           marker.respondsToUserInteraction,
                           let userInputLabels = marker.userInputLabels,
                           !userInputLabels.isEmpty
                       else {
                           return nil
                       }
                       return userInputLabels
                       
                   case .never:
                       return nil
                   }
               }()

                guard let userInputLabels else { return nil }
                
                return .init(titles: userInputLabels, color: color)
            }()

            super.init(frame: .zero)

            markerView.backgroundColor = color.withAlphaComponent(0.3)
            addSubview(markerView)

            descriptionLabel.text =
                showCustomContentInDescription
                ? Strings.moreContentAvailableText(for: marker.accessibilityLanguage)
                : showActionsAvailableInDescription
                ? Strings.actionsAvailableText(for: marker.accessibilityLanguage)
                : marker.description
            
            descriptionLabel.font = Metrics.descriptionLabelFont
            descriptionLabel.textColor = .black
            descriptionLabel.numberOfLines = 0
            addSubview(descriptionLabel)

            hintLabel.map(addSubview)
            customActionsView.map(addSubview)
            customContentView.map(addSubview)
            customRotorsView.map(addSubview)
            userInputLabelsView.map(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let markerView: UIView = .init()

        private let descriptionLabel: UILabel = .init()

        private let hintLabel: UILabel?

        private let customActionsView: CustomActionsView?

        private let customContentView: CustomContentView?

        private let customRotorsView: CustomRotorsView?

        private let userInputLabelsView: PillsView?

        // MARK: - UIView

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let labelSizeToFit = CGSize(
                width: size.width - Metrics.markerSize - Metrics.markerToLabelSpacing,
                height: .greatestFiniteMagnitude
            )

            descriptionLabel.numberOfLines = 1
            let descriptionLabelSingleLineHeight = descriptionLabel.sizeThatFits(labelSizeToFit).height
            let markerSizeAboveDescriptionLabel = (Metrics.markerSize - descriptionLabelSingleLineHeight) / 2

            descriptionLabel.numberOfLines = 0
            let descriptionLabelSize = descriptionLabel.sizeThatFits(labelSizeToFit)

            let hintLabelSize = hintLabel?.sizeThatFits(labelSizeToFit) ?? .zero

            let customActionsSize = customActionsView?.sizeThatFits(labelSizeToFit) ?? .zero
            
            let customContentSize = customContentView?.sizeThatFits(labelSizeToFit) ?? .zero
            
            let customRotorsSize = customRotorsView?.sizeThatFits(labelSizeToFit) ?? .zero
            
            let userInputLabelsViewSize = userInputLabelsView?.sizeThatFits(labelSizeToFit) ?? .zero

            let widthComponents = [
                Metrics.markerSize,
                Metrics.markerToLabelSpacing,
                max(
                    descriptionLabelSize.width,
                    hintLabelSize.width,
                    customActionsSize.width,
                    customContentSize.width,
                    customRotorsSize.width,
                    userInputLabelsViewSize.width
                ),
            ]

            let heightComponents = [
                markerSizeAboveDescriptionLabel,
                descriptionLabelSize.height,
                (hintLabelSize.height == 0 ? 0 : hintLabelSize.height + Metrics.interSectionSpacing),
                (customActionsSize.height == 0 ? 0 : customActionsSize.height + Metrics.interSectionSpacing),
                (customContentSize.height == 0 ? 0 : customContentSize.height + Metrics.interSectionSpacing),
                (customRotorsSize.height == 0 ? 0 : customRotorsSize.height + Metrics.interSectionSpacing),
                (userInputLabelsViewSize.height == 0 ? 0 : userInputLabelsViewSize.height + Metrics.interSectionSpacing)
            ]

            return CGSize(
                width: widthComponents.reduce(0, +),
                height: max(
                    Metrics.markerSize,
                    heightComponents.reduce(0, +)
                )
            )
        }

        override func layoutSubviews() {
            markerView.frame = CGRect(x: 0, y: 0, width: Metrics.markerSize, height: Metrics.markerSize)

            let labelSizeToFit = CGSize(
                width: bounds.size.width - Metrics.markerSize - Metrics.markerToLabelSpacing,
                height: .greatestFiniteMagnitude
            )

            descriptionLabel.numberOfLines = 1
            let descriptionLabelSingleLineHeight = descriptionLabel.sizeThatFits(labelSizeToFit).height

            descriptionLabel.numberOfLines = 0
            let descriptionLabelSizeThatFits = descriptionLabel.sizeThatFits(labelSizeToFit)

            descriptionLabel.frame = .init(
                x: markerView.frame.maxX + Metrics.markerToLabelSpacing,
                y: markerView.frame.minY + (markerView.frame.height - descriptionLabelSingleLineHeight) / 2,
                width: descriptionLabelSizeThatFits.width,
                height: descriptionLabelSizeThatFits.height
            )

            if let hintLabel {
                hintLabel.bounds.size = hintLabel.sizeThatFits(labelSizeToFit)
                hintLabel.frame.origin = .init(
                    x: descriptionLabel.frame.minX,
                    y: descriptionLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }

            if let customActionsView {
                let alignmentLabel = hintLabel ?? descriptionLabel

                customActionsView.bounds.size = customActionsView.sizeThatFits(labelSizeToFit)
                customActionsView.frame.origin = .init(
                    x: alignmentLabel.frame.minX,
                    y: alignmentLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }
            
            if let customContentView {
                let alignmentLabel = customActionsView ?? hintLabel ?? descriptionLabel

                customContentView.bounds.size = customContentView.sizeThatFits(labelSizeToFit)
                customContentView.frame.origin = .init(
                    x: alignmentLabel.frame.minX,
                    y: alignmentLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }
            
            if let customRotorsView {
                let alignmentLabel = customContentView ?? customActionsView ?? hintLabel ?? descriptionLabel

                customRotorsView.bounds.size = customRotorsView.sizeThatFits(labelSizeToFit)
                customRotorsView.frame.origin = .init(
                    x: alignmentLabel.frame.minX,
                    y: alignmentLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }
            
            if let userInputLabelsView  {
                let alignmentControl = customRotorsView ?? customContentView ?? customActionsView ?? hintLabel ?? descriptionLabel
                
                userInputLabelsView.bounds.size = userInputLabelsView.sizeThatFits(labelSizeToFit)
                userInputLabelsView.frame.origin = CGPoint(
                    x: alignmentControl.frame.minX,
                    y: alignmentControl.frame.maxY + Metrics.interSectionSpacing
                )
            }
        }

        // MARK: - Private

        internal enum Metrics {

            static let minimumWidth: CGFloat = 284

            static let markerSize: CGFloat = 14
            static let markerToLabelSpacing: CGFloat = 16
            static let interSectionSpacing: CGFloat = 4

            static let descriptionLabelFont = UIFont.systemFont(ofSize: 12)
            static let hintLabelFont = UIFont.italicSystemFont(ofSize: 12)

        }


    }
}

internal extension AccessibilityMarker {
    func displayRotors(_ mode: AccessibilityContentDisplayMode) -> [AccessibilityMarker.CustomRotor] {
        switch mode {
        case .always:
            return customRotors
        case .whenOverridden:
            return customRotors.filter { !$0.resultMarkers.isEmpty }
        case .never:
            return []
        }
    }
}

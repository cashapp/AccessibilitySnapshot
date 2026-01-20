import UIKit
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif

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
            
            self.attributedLabelView = {
                guard let attributedLabel = marker.attributedLabel else { return nil }
                let view = AttributedLabelView(attributedString: attributedLabel, type: .label)
                // Only show if there are accessibility attributes to display
                return view.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).height > 0 ? view : nil
            }()
            
            self.attributedValueView = {
                guard let attributedValue = marker.attributedValue else { return nil }
                let view = AttributedLabelView(attributedString: attributedValue, type: .value)
                // Only show if there are accessibility attributes to display
                return view.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).height > 0 ? view : nil
            }()
            
            self.attributedHintView = {
                guard let attributedHint = marker.attributedHint else { return nil }
                let view = AttributedLabelView(attributedString: attributedHint, type: .hint)
                // Only show if there are accessibility attributes to display
                return view.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).height > 0 ? view : nil
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
            attributedLabelView.map(addSubview)
            attributedValueView.map(addSubview)
            attributedHintView.map(addSubview)
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
        
        private let attributedLabelView: AttributedLabelView?
        
        private let attributedValueView: AttributedLabelView?
        
        private let attributedHintView: AttributedLabelView?
        
        /// Ordered list of secondary views that appear below the description label.
        private var secondaryViews: [UIView] {
            return [
                hintLabel,
                customActionsView,
                customContentView,
                customRotorsView,
                userInputLabelsView,
                attributedLabelView,
                attributedValueView,
                attributedHintView
            ].compactMap { $0 }
        }

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

            // Calculate sizes for all secondary views
            let secondaryViewSizes = secondaryViews.map { $0.sizeThatFits(labelSizeToFit) }

            // Width is the max of description and all secondary views
            let maxSecondaryWidth = secondaryViewSizes.map(\.width).max() ?? 0
            let contentWidth = max(descriptionLabelSize.width, maxSecondaryWidth)

            let widthComponents = [
                Metrics.markerSize,
                Metrics.markerToLabelSpacing,
                contentWidth
            ]

            // Height is description + all secondary views with spacing
            let secondaryHeight = secondaryViewSizes
                .filter { $0.height > 0 }
                .map { $0.height + Metrics.interSectionSpacing }
                .reduce(0, +)

            let heightComponents = [
                markerSizeAboveDescriptionLabel,
                descriptionLabelSize.height,
                secondaryHeight
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

            // Layout secondary views in order, each positioned below the previous
            var previousView: UIView = descriptionLabel
            for view in secondaryViews {
                view.bounds.size = view.sizeThatFits(labelSizeToFit)
                view.frame.origin = CGPoint(
                    x: descriptionLabel.frame.minX,
                    y: previousView.frame.maxY + Metrics.interSectionSpacing
                )
                previousView = view
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

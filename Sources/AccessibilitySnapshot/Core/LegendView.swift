import UIKit
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif

internal extension AccessibilitySnapshotView {
    
    final class ElementMarkerView: UIView {
        
        enum Style {
            case pill, box
        }
        
        private enum Metrics {
            static let ElementIndexFont = UIFont.systemFont(ofSize: 12)
        }
        
        private let indexLabel = UILabel()
        private let style: Style
        
        
        init(frame: CGRect = .zero, color: UIColor, index: Int?, style: Style = .box) {
            self.style = style
            super.init(frame: frame)
            indexLabel.numberOfLines = 1
            indexLabel.text = index.map(String.init) ?? nil
            indexLabel.font = Metrics.ElementIndexFont
            addSubview(indexLabel)
            backgroundColor = color

            switch style {
            case .pill:
                indexLabel.textColor = .lightText
                layer.borderColor = UIColor.lightText.cgColor
                layer.borderWidth = 1
                layer.shadowOffset = CGSize(width: 1, height: 1)
                layer.shadowRadius = 2
            case .box:
                indexLabel.textColor = .darkText
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
           let labelSize = indexLabel.sizeThatFits(size)
            if labelSize.width > labelSize.height {
                return labelSize.applying(.init(scaleX: 1.1, y: 1.1))
            }
            return CGSize(width: labelSize.height, height: labelSize.height).applying(.init(scaleX: 1.1, y: 1.1))
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()

            indexLabel.sizeToFit()
            indexLabel.frame = CGRect(x: (bounds.size.width - indexLabel.frame.width) / 2,
                                      y: (bounds.size.height - indexLabel.frame.height) / 2,
                                      width: indexLabel.frame.width,
                                      height: indexLabel.frame.height)
            
            
            layer.cornerRadius = style == .pill ? indexLabel.frame.height / 2 : 0.0
        }
    }
    
    
    final class LegendView: UIView {
        
        // MARK: - Life Cycle
        
        init(marker: AccessibilityMarker, color: UIColor, configuration: AccessibilitySnapshotConfiguration.Legend) {
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
            
            // If our description and hint are both empty, and we dont have custom actions, but we do have custom content, we'll use the description label
            // to show the "More Content Available" text, since this makes our layout simpler when we align to the marker.
            let showCustomContentInDescription = (marker.description.isEmpty && !showActionsAvailableInDescription && !marker.customContent.isEmpty)
            
            self.customContentView = {
                guard !marker.customContent.isEmpty else { return nil }
                
                return .init(
                    customContentText: showCustomContentInDescription
                    ? nil
                    : Strings.moreContentAvailableText(for: marker.accessibilityLanguage),
                    customContent: marker.customContent
                )
            }()
            
            self.userInputLabelsView = {
    
               let userInputLabels: [String]? = {
                   
                   switch configuration.includesUserInputLabels {
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
            
            markerView = ElementMarkerView(color: color.withAlphaComponent(0.3), index: elementIndex)

            super.init(frame: .zero)
            
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
            userInputLabelsView.map(addSubview)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    
        // MARK: - Private Properties
        
        private let markerView: ElementMarkerView
        
        private let descriptionLabel: UILabel = .init()
        
        private let hintLabel: UILabel?
        
        private let customActionsView: CustomActionsView?
        
        private let customContentView: CustomContentView?
        
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
            
            let userInputLabelsViewSize = userInputLabelsView?.sizeThatFits(labelSizeToFit) ?? .zero
            
            let widthComponents = [
                Metrics.markerSize,
                Metrics.markerToLabelSpacing,
                max(
                    descriptionLabelSize.width,
                    hintLabelSize.width,
                    customActionsSize.width,
                    customContentSize.width,
                    userInputLabelsViewSize.width
                ),
            ]
            
            let heightComponents = [
                markerSizeAboveDescriptionLabel,
                descriptionLabelSize.height,
                (hintLabelSize.height == 0 ? 0 : hintLabelSize.height + Metrics.interSectionSpacing),
                (customActionsSize.height == 0 ? 0 : customActionsSize.height + Metrics.interSectionSpacing),
                (customContentSize.height == 0 ? 0 : customContentSize.height + Metrics.interSectionSpacing),
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
            
            if let hintLabel = hintLabel {
                hintLabel.bounds.size = hintLabel.sizeThatFits(labelSizeToFit)
                hintLabel.frame.origin = .init(
                    x: descriptionLabel.frame.minX,
                    y: descriptionLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }
            
            if let customActionsView = customActionsView {
                let alignmentLabel = hintLabel ?? descriptionLabel
                
                customActionsView.bounds.size = customActionsView.sizeThatFits(labelSizeToFit)
                customActionsView.frame.origin = .init(
                    x: alignmentLabel.frame.minX,
                    y: alignmentLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }
            
            if let customContentView = customContentView {
                let alignmentLabel = customActionsView ?? hintLabel ?? descriptionLabel
                
                customContentView.bounds.size = customContentView.sizeThatFits(labelSizeToFit)
                customContentView.frame.origin = .init(
                    x: alignmentLabel.frame.minX,
                    y: alignmentLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }
            
            if let userInputLabelsView = userInputLabelsView {
                let alignmentControl = customContentView ?? customActionsView ?? hintLabel ?? descriptionLabel
                
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

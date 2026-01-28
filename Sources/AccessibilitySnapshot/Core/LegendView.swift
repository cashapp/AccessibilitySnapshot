import UIKit
import AccessibilitySnapshotParser

internal extension AccessibilitySnapshotView {
    final class LegendView: UIView {

        // MARK: - Life Cycle

        init(element: AccessibilityElement, color: UIColor, configuration: AccessibilitySnapshotConfiguration) {
            self.hintLabel = element.hint.map {
                let label = UILabel()
                label.text = $0
                label.font = Metrics.hintLabelFont
                label.textColor = .init(white: 0.3, alpha: 1.0)
                label.numberOfLines = 0
                return label
            }

            // If our description and hint are both empty, but we have custom actions, we'll use the description label
            // to show the "Actions Available" text, since this makes our layout simpler when we align to the element.
            let showActionsAvailableInDescription = (element.description.isEmpty && !element.customActions.isEmpty)

            self.customActionsView = {
                guard !element.customActions.isEmpty else { return nil }

                return .init(
                    actionsAvailableText: showActionsAvailableInDescription
                        ? nil
                        : Strings.actionsAvailableText(for: element.accessibilityLanguage),
                    customActions: element.customActions
                )
            }()

            // If our description and hint are both empty, and we don't have custom actions, but we do have custom content, we'll use the description label
            // to show the "Custom Content Available" text, since this makes our layout simpler when we align to the element.
            let showCustomContentInDescription = (element.description.isEmpty &&
                                                  !showActionsAvailableInDescription &&
                                                  !element.customContent.isEmpty)

            self.customContentView = {
                guard !element.customContent.isEmpty else { return nil }

                return .init(
                    customContentText: showCustomContentInDescription
                        ? nil
                        : Strings.moreContentAvailableText(for: element.accessibilityLanguage),
                    customContent: element.customContent
                )
            }()

            let rotors = element.displayRotors(configuration.rotors.displayMode)
            self.customRotorsView = rotors.isEmpty ? nil : .init(
                    rotors: rotors,
                    locale: element.accessibilityLanguage
                )

            self.userInputLabelsView = {

               let userInputLabels: [String]? = {

                   switch configuration.inputLabelDisplayMode {
                   case .always:
                       guard let labels = element.userInputLabels, !labels.isEmpty else {
                           /// If no labels are provided the accessibility label will be used, split on spaces.
                           var labels = element.label?.split(separator: " ").map(String.init) ?? []

                           /// The button trait precedes the adjustable trait if both are present.
                           if  element.traits.contains(.button) {
                               labels.append(Strings.buttonInputLabelText(for: element.accessibilityLanguage))
                           }
                           if element.traits.contains(.adjustable) {
                               labels.append(Strings.adjustableInputLabelText(for: element.accessibilityLanguage))
                           }

                           return labels
                       }
                       return element.userInputLabels

                   case .whenOverridden:
                       guard
                           element.respondsToUserInteraction,
                           let userInputLabels = element.userInputLabels,
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
                ? Strings.moreContentAvailableText(for: element.accessibilityLanguage)
                : showActionsAvailableInDescription
                ? Strings.actionsAvailableText(for: element.accessibilityLanguage)
                : element.description

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

// MARK: - Container Legend View

internal extension AccessibilitySnapshotView {
    /// A legend view that displays container information with nested children.
    /// Uses a dashed border with a pill-shaped label on the top edge.
    final class ContainerLegendView: UIView {

        // MARK: - Life Cycle

        init(container: AccessibilityContainer, color: UIColor, childViews: [UIView]) {
            self.container = container
            self.childViews = childViews
            self.containerColor = color

            super.init(frame: .zero)

            // Dashed border layer
            borderLayer.fillColor = nil
            borderLayer.strokeColor = color.withAlphaComponent(0.5).cgColor
            borderLayer.lineWidth = 1
            borderLayer.lineDashPattern = [4, 4]
            layer.addSublayer(borderLayer)

            // Pill container (colored background with white text)
            pillView.backgroundColor = color
            addSubview(pillView)

            // Pill label
            let labelText: String
            if let containerLabel = container.label, !containerLabel.isEmpty {
                labelText = "\(container.typeDescription): \(containerLabel)"
            } else {
                labelText = container.typeDescription
            }
            pillLabel.text = labelText
            pillLabel.font = .systemFont(ofSize: 9, weight: .medium)
            pillLabel.textColor = .white
            pillLabel.layer.shadowColor = UIColor.black.cgColor
            pillLabel.layer.shadowOffset = CGSize(width: 0, height: 0.5)
            pillLabel.layer.shadowRadius = 1
            pillLabel.layer.shadowOpacity = 0.3
            pillView.addSubview(pillLabel)

            // Pill styling
            pillView.layer.cornerRadius = Metrics.pillHeight / 2

            // Content view for children
            addSubview(contentView)

            // Add child views to content view
            for childView in childViews {
                contentView.addSubview(childView)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let container: AccessibilityContainer
        private let childViews: [UIView]
        private let containerColor: UIColor

        private let borderLayer = CAShapeLayer()
        private let pillView = UIView()
        private let pillLabel = UILabel()
        private let contentView = UIView()

        // MARK: - Layout

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let contentWidth = size.width - 2 * Metrics.borderInset
            let childrenHeight = childViews.reduce(CGFloat(0)) { total, child in
                let childHeight = child.sizeThatFits(CGSize(width: contentWidth - 2 * Metrics.contentPadding, height: .greatestFiniteMagnitude)).height
                return total + childHeight + (total > 0 ? Metrics.childSpacing : 0)
            }

            let totalHeight = Metrics.pillHeight / 2 + Metrics.contentTopPadding + childrenHeight + Metrics.contentBottomPadding

            return CGSize(width: size.width, height: totalHeight)
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            // Calculate pill size
            let pillLabelSize = pillLabel.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: Metrics.pillHeight))
            let pillWidth = pillLabelSize.width + 2 * Metrics.pillPadding

            // Position pill at top-left, centered on the border line
            pillView.frame = CGRect(
                x: Metrics.borderInset + Metrics.pillLeftOffset,
                y: 0,
                width: pillWidth,
                height: Metrics.pillHeight
            )
            pillLabel.frame = CGRect(
                x: Metrics.pillPadding,
                y: (Metrics.pillHeight - pillLabelSize.height) / 2,
                width: pillLabelSize.width,
                height: pillLabelSize.height
            )

            // Border starts at pill center vertically
            let borderTop = Metrics.pillHeight / 2
            let borderRect = CGRect(
                x: Metrics.borderInset,
                y: borderTop,
                width: bounds.width - 2 * Metrics.borderInset,
                height: bounds.height - borderTop
            )
            borderLayer.path = UIBezierPath(roundedRect: borderRect, cornerRadius: Metrics.borderRadius).cgPath

            // Content view inside the border
            contentView.frame = CGRect(
                x: Metrics.borderInset,
                y: borderTop + Metrics.contentTopPadding,
                width: bounds.width - 2 * Metrics.borderInset,
                height: bounds.height - borderTop - Metrics.contentTopPadding - Metrics.contentBottomPadding
            )

            // Layout children with padding on both sides
            var yOffset: CGFloat = 0
            let availableChildWidth = contentView.bounds.width - 2 * Metrics.contentPadding
            for childView in childViews {
                let childSize = childView.sizeThatFits(CGSize(width: availableChildWidth, height: .greatestFiniteMagnitude))
                childView.frame = CGRect(x: Metrics.contentPadding, y: yOffset, width: availableChildWidth, height: childSize.height)
                yOffset += childSize.height + Metrics.childSpacing
            }
        }

        private enum Metrics {
            static let borderInset: CGFloat = 0
            static let borderRadius: CGFloat = 6
            static let pillHeight: CGFloat = 14
            static let pillPadding: CGFloat = 6
            static let pillLeftOffset: CGFloat = 8
            static let contentPadding: CGFloat = 8
            static let contentTopPadding: CGFloat = 8
            static let contentBottomPadding: CGFloat = 8
            static let childSpacing: CGFloat = 4
        }
    }
}

// MARK: - Container Type Description

extension AccessibilityContainer {
    var typeDescription: String {
        switch type {
        case .none:
            return "Container"
        case .dataTable:
            return "Data Table"
        case .list:
            return "List"
        case .landmark:
            return "Landmark"
        case .semanticGroup:
            return "Semantic Group"
        @unknown default:
            return "Container"
        }
    }
}

internal extension AccessibilityElement {
    func displayRotors(_ mode: AccessibilityContentDisplayMode) -> [AccessibilityElement.CustomRotor] {
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

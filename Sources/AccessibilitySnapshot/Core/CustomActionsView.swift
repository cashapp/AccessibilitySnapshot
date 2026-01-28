import AccessibilitySnapshotParser
import UIKit

extension AccessibilitySnapshotView {
    final class CustomActionsView: UIView {
        // MARK: - Life Cycle

        init(actionsAvailableText: String?, customActions: [AccessibilityMarker.CustomAction]) {
            actionLabels = customActions.map {
                let iconView: UIView
                if let image = $0.image {
                    let imageView = UIImageView()
                    imageView.image = image
                    imageView.tintColor = .darkGray
                    iconView = imageView
                } else {
                    iconView = LetterIconView(letter: $0.name.uppercased().first ?? "?", size: CGSize(width: 20, height: 20))
                }

                let actionDescriptionLabel = UILabel()
                actionDescriptionLabel.text = $0.name
                actionDescriptionLabel.font = Metrics.font
                actionDescriptionLabel.textColor = .black
                actionDescriptionLabel.numberOfLines = 0

                return (iconView, actionDescriptionLabel)
            }

            if let actionsAvailableText = actionsAvailableText {
                let label = UILabel()
                label.text = actionsAvailableText
                label.font = Metrics.font
                label.textColor = .black
                actionsAvailableLabel = label

            } else {
                actionsAvailableLabel = nil
            }

            super.init(frame: .zero)

            actionsAvailableLabel.map(addSubview)

            actionLabels.forEach {
                addSubview($0)
                addSubview($1)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let actionsAvailableLabel: UILabel?

        private let actionLabels: [(UIView, UILabel)]

        // MARK: - UIView

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let actionsAvailableHeight = actionsAvailableLabel?.sizeThatFits(size).height ?? -Metrics.verticalSpacing

            guard let (firstIconView, _) = actionLabels.first else {
                return .init(width: max(size.width, 0), height: actionsAvailableHeight)
            }

            let descriptionWidthToFit = [
                Metrics.actionIconInset,
                firstIconView.sizeThatFits(size).width,
                Metrics.iconToDescriptionSpacing,
            ].reduce(size.width, -)
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)

            let height = actionLabels
                .map { $1.sizeThatFits(descriptionSizeToFit).height }
                .reduce(actionsAvailableHeight) {
                    $0 + Metrics.verticalSpacing + $1
                }

            return .init(width: size.width, height: height)
        }

        override func layoutSubviews() {
            let firstPairYPosition: CGFloat
            if let actionsAvailableLabel = actionsAvailableLabel {
                actionsAvailableLabel.bounds.size = actionsAvailableLabel.sizeThatFits(bounds.size)
                actionsAvailableLabel.frame.origin = .zero

                firstPairYPosition = actionsAvailableLabel.frame.maxY + Metrics.verticalSpacing

            } else {
                firstPairYPosition = 0
            }

            guard !actionLabels.isEmpty else {
                return
            }

            // Size icon heights to match a single line of text, width adjusts for aspect ratio
            let singleLineHeight = Metrics.font.lineHeight

            // First pass: calculate all icon sizes and find the maximum width
            let iconSizes: [CGSize] = actionLabels.map { iconView, _ in
                let intrinsicSize = iconView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                let iconWidth: CGFloat
                if intrinsicSize.height > 0 {
                    iconWidth = singleLineHeight * (intrinsicSize.width / intrinsicSize.height)
                } else {
                    iconWidth = singleLineHeight
                }
                return CGSize(width: iconWidth, height: singleLineHeight)
            }

            let maxIconWidth = iconSizes.map(\.width).max() ?? singleLineHeight

            // Calculate description width based on max icon width
            let descriptionXPosition = Metrics.actionIconInset + maxIconWidth + Metrics.iconToDescriptionSpacing
            let descriptionWidthToFit = bounds.width - descriptionXPosition
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)

            // Second pass: position all elements
            var yPosition = firstPairYPosition
            for (index, (iconView, descriptionLabel)) in actionLabels.enumerated() {
                let iconSize = iconSizes[index]
                iconView.bounds.size = iconSize
                descriptionLabel.bounds.size = descriptionLabel.sizeThatFits(descriptionSizeToFit)

                // Right-align icon: position so right edge aligns with (actionIconInset + maxIconWidth)
                let iconXPosition = Metrics.actionIconInset + maxIconWidth - iconSize.width
                iconView.frame.origin = .init(x: iconXPosition, y: yPosition)

                // Left-align description label
                descriptionLabel.frame.origin = .init(x: descriptionXPosition, y: yPosition)

                yPosition = descriptionLabel.frame.maxY + Metrics.verticalSpacing
            }
        }

        // MARK: - Private Types

        private enum Metrics {
            static let verticalSpacing: CGFloat = 4
            static let actionIconInset: CGFloat = 4
            static let iconToDescriptionSpacing: CGFloat = 4

            static let font: UIFont = .systemFont(ofSize: 12)
        }
    }
}

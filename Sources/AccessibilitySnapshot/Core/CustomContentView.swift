import UIKit
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif

internal extension AccessibilitySnapshotView {
    
    final class CustomContentView: UIView {
        
        // MARK: - Life Cycle
        
        init(customContentText: String?, customContent: [AccessibilityMarker.CustomContent]) {
            
            contentLabels = customContent.map { content in
                let iconLabel = UILabel()
                iconLabel.text = "↓"
                iconLabel.font = Metrics.font
                iconLabel.numberOfLines = 0
                
                let customContentLabel = UILabel()
                customContentLabel.font = content.isImportant ? Metrics.boldFont : Metrics.font
                customContentLabel.numberOfLines = 0
                customContentLabel.text = {
                    guard !content.value.isEmpty else { return content.label }
                    return "\(content.label): \(content.value)"
                }()
                
                return (iconLabel, customContentLabel)
            }

            if let customContentText = customContentText {
                let label = UILabel()
                label.text = customContentText
                label.font = Metrics.font
                self.customContentLabel = label

            } else {
                self.customContentLabel = nil
            }

            super.init(frame: .zero)

            customContentLabel.map(addSubview)

            contentLabels.forEach {
                addSubview($0)
                addSubview($1)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let customContentLabel: UILabel?

        private let contentLabels: [(UILabel, UILabel)]

        // MARK: - UIView

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let actionsAvailableHeight = customContentLabel?.sizeThatFits(size).height ?? -Metrics.verticalSpacing

            guard let (firstIconLabel, _) = contentLabels.first else {
                return .init(width: max(size.width, 0), height: actionsAvailableHeight)
            }

            let descriptionWidthToFit = [
                Metrics.contentIconInset,
                firstIconLabel.sizeThatFits(size).width,
                Metrics.iconToDescriptionSpacing,
            ].reduce(size.width, -)
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)

            let height = contentLabels
                .map { $1.sizeThatFits(descriptionSizeToFit).height }
                .reduce(actionsAvailableHeight) {
                    $0 + Metrics.verticalSpacing + $1
                }

            return .init(width: size.width, height: height)
        }

        override func layoutSubviews() {
            let firstPairYPosition: CGFloat
            if let customContentLabel {
                customContentLabel.bounds.size = customContentLabel.sizeThatFits(bounds.size)
                customContentLabel.frame.origin = .zero

                firstPairYPosition = customContentLabel.frame.maxY + Metrics.verticalSpacing

            } else {
                firstPairYPosition = 0
            }

            guard let (firstIconLabel, firstDescriptionLabel) = contentLabels.first else {
                return
            }

            firstIconLabel.sizeToFit()

            // All of the icon labels should be the same size, so we only need to calculate the description width once.
            let descriptionWidthToFit = [
                Metrics.contentIconInset,
                firstIconLabel.bounds.width,
                Metrics.iconToDescriptionSpacing,
            ].reduce(bounds.width, -)
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)

            firstDescriptionLabel.bounds.size = firstDescriptionLabel.sizeThatFits(descriptionSizeToFit)

            firstIconLabel.frame.origin = .init(x: Metrics.contentIconInset, y: firstPairYPosition)

            let descriptionXPosition = firstIconLabel.frame.maxX + Metrics.iconToDescriptionSpacing

            firstDescriptionLabel.frame.origin = .init(x: descriptionXPosition, y: firstPairYPosition)

            let zippedContentLabels = zip(contentLabels.dropFirst(), contentLabels)
            for ((iconLabel, descriptionLabel), (_, previousDescriptionLabel)) in zippedContentLabels {
                iconLabel.sizeToFit()
                descriptionLabel.bounds.size = descriptionLabel.sizeThatFits(descriptionSizeToFit)

                let yPosition = previousDescriptionLabel.frame.maxY + Metrics.verticalSpacing

                iconLabel.frame.origin = .init(x: Metrics.contentIconInset, y: yPosition)
                descriptionLabel.frame.origin = .init(x: descriptionXPosition, y: yPosition)
            }
        }

        // MARK: - Private Types
        
        private enum Metrics {
            
            static let verticalSpacing: CGFloat = 4
            static let contentIconInset: CGFloat = 4
            static let iconToDescriptionSpacing: CGFloat = 4
            
            static let font: UIFont = .systemFont(ofSize: 12)
            static let boldFont: UIFont = .boldSystemFont(ofSize: 12)
            
        }
    }
}

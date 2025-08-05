import UIKit
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif

internal extension AccessibilitySnapshotView {
    
    final class CustomActionsView: UIView {
        
        // MARK: - Life Cycle
        
        init(actionsAvailableText: String?, customActions: [String]) {
            actionLabels = customActions.map {
                let iconLabel = UILabel()
                iconLabel.text = "↓"
                iconLabel.font = Metrics.font
                iconLabel.textColor = .black
                iconLabel.numberOfLines = 0
                
                let actionDescriptionLabel = UILabel()
                actionDescriptionLabel.text = $0
                actionDescriptionLabel.font = Metrics.font
                actionDescriptionLabel.textColor = .black
                actionDescriptionLabel.numberOfLines = 0
                
                return (iconLabel, actionDescriptionLabel)
            }
            
            if let actionsAvailableText = actionsAvailableText {
                let label = UILabel()
                label.text = actionsAvailableText
                label.font = Metrics.font
                label.textColor = .black
                self.actionsAvailableLabel = label
                
            } else {
                self.actionsAvailableLabel = nil
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
        
        private let actionLabels: [(UILabel, UILabel)]
        
        // MARK: - UIView
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let actionsAvailableHeight = actionsAvailableLabel?.sizeThatFits(size).height ?? -Metrics.verticalSpacing
            
            guard let (firstIconLabel, _) = actionLabels.first else {
                return .init(width: max(size.width, 0), height: actionsAvailableHeight)
            }
            
            let descriptionWidthToFit = [
                Metrics.actionIconInset,
                firstIconLabel.sizeThatFits(size).width,
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
            
            guard let (firstIconLabel, firstDescriptionLabel) = actionLabels.first else {
                return
            }
            
            firstIconLabel.sizeToFit()
            
            // All of the icon labels should be the same size, so we only need to calculate the description width once.
            let descriptionWidthToFit = [
                Metrics.actionIconInset,
                firstIconLabel.bounds.width,
                Metrics.iconToDescriptionSpacing,
            ].reduce(bounds.width, -)
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)
            
            firstDescriptionLabel.bounds.size = firstDescriptionLabel.sizeThatFits(descriptionSizeToFit)
            
            firstIconLabel.frame.origin = .init(x: Metrics.actionIconInset, y: firstPairYPosition)
            
            let descriptionXPosition = firstIconLabel.frame.maxX + Metrics.iconToDescriptionSpacing
            
            firstDescriptionLabel.frame.origin = .init(x: descriptionXPosition, y: firstPairYPosition)
            
            let zippedActionLabels = zip(actionLabels.dropFirst(), actionLabels)
            for ((iconLabel, descriptionLabel), (_, previousDescriptionLabel)) in zippedActionLabels {
                iconLabel.sizeToFit()
                descriptionLabel.bounds.size = descriptionLabel.sizeThatFits(descriptionSizeToFit)
                
                let yPosition = previousDescriptionLabel.frame.maxY + Metrics.verticalSpacing
                
                iconLabel.frame.origin = .init(x: Metrics.actionIconInset, y: yPosition)
                descriptionLabel.frame.origin = .init(x: descriptionXPosition, y: yPosition)
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

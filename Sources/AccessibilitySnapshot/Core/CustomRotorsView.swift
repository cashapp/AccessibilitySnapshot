import UIKit
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif


internal extension AccessibilitySnapshotView {
    
    final class CustomRotorsView: UIView {
        
        // MARK: - Life Cycle
        
        init(customRotorsText: String?, rotors: [AccessibilityMarker.CustomRotor], locale: String?) {
            
            rotorLabels = rotors.map { rotor in
                let iconLabel = UILabel()
                iconLabel.text = "↺ \(rotor.name):"
                iconLabel.font = Metrics.boldFont
                iconLabel.numberOfLines = 0
                
                let resultsLabel = UILabel()
                resultsLabel.font = Metrics.font
                resultsLabel.numberOfLines = 0
                resultsLabel.text = {
                    guard !rotor.results.isEmpty else { return Strings.noResultsText(for: locale) }
                    return rotor.results.map({ "- \($0.elementDescription)" }).joined(separator: "\n")
                }()
                return (iconLabel, resultsLabel)
            }
            
            let label = UILabel()
            label.text = customRotorsText
            label.font = Metrics.font
            label.numberOfLines = 0
            self.customRotorsLabel = label
            
            
            super.init(frame: .zero)
            
            customRotorsLabel.map(addSubview)
            
            rotorLabels.forEach {
                addSubview($0)
                addSubview($1)
            }
        }
        
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        // MARK: - Private Properties
        
        
        private let customRotorsLabel: UILabel?
        private let rotorLabels:  [(UILabel, UILabel)]
        
        
        
        // MARK: - UIView
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let rotorsLabelHeight = customRotorsLabel?.sizeThatFits(size).height ?? -Metrics.verticalSpacing
            
            guard let (firstIconLabel, _) = rotorLabels.first else {
                return .init(width: max(size.width, 0), height: rotorsLabelHeight)
            }
            
            let firstIconLabelSize = firstIconLabel.sizeThatFits(size)
            let descriptionWidthToFit = [
                Metrics.contentIconInset,
                firstIconLabelSize.width,
            ].reduce(size.width, -)
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)
            
            let height = rotorLabels
                .map { $1.sizeThatFits(descriptionSizeToFit).height }
                .reduce(rotorsLabelHeight) {
                    $0 + Metrics.verticalSpacing + $1
                } + firstIconLabelSize.height
            
            return .init(width: size.width, height: height)
        }
        
        override func layoutSubviews() {
            let firstPairYPosition: CGFloat
            if let customRotorsLabel {
                customRotorsLabel.bounds.size = customRotorsLabel.sizeThatFits(bounds.size)
                customRotorsLabel.frame.origin = .zero
                
                firstPairYPosition = customRotorsLabel.frame.maxY + Metrics.verticalSpacing
                
            } else {
                firstPairYPosition = 0
            }
            
            guard let (firstIconLabel, firstDescriptionLabel) = rotorLabels.first else {
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
            
            let descriptionXPosition = firstIconLabel.frame.origin.x + Metrics.iconToDescriptionSpacing
            
            firstDescriptionLabel.frame.origin = .init(x: descriptionXPosition, y: firstIconLabel.frame.maxY + Metrics.verticalSpacing)
            
            let zippedRotorLabels = zip(rotorLabels.dropFirst(), rotorLabels)
            for ((iconLabel, descriptionLabel), (previousIconLabel, previousDescriptionLabel)) in zippedRotorLabels {
                iconLabel.sizeToFit()
                descriptionLabel.bounds.size = descriptionLabel.sizeThatFits(descriptionSizeToFit)
                
                let yPosition = previousDescriptionLabel.frame.maxY + Metrics.verticalSpacing
                
                iconLabel.frame.origin = .init(x: Metrics.contentIconInset, y: yPosition)
                descriptionLabel.frame.origin = .init(x: descriptionXPosition, y: iconLabel.frame.maxY + Metrics.verticalSpacing)
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

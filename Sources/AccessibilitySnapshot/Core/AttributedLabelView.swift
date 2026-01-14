import UIKit
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif

internal extension AccessibilitySnapshotView {
    
    /// A view that displays accessibility-related attributes from an attributed string.
    /// Used for both attributed labels and attributed values.
    final class AttributedLabelView: UIView {
        
        // MARK: - Public Types
        
        enum AttributeType {
            case label
            case value
            case hint
            
            var headerText: String {
                switch self {
                case .label:
                    return "Label Attributes:"
                case .value:
                    return "Value Attributes:"
                case .hint:
                    return "Hint Attributes:"
                }
            }
        }
        
        // MARK: - Life Cycle
        
        init(attributedString: NSAttributedString, type: AttributeType) {
            let formattedAttributes = Self.formatAccessibilityAttributes(from: attributedString)
            
            if !formattedAttributes.isEmpty {
                let label = UILabel()
                label.text = type.headerText
                label.font = Metrics.headerFont
                label.textColor = .darkGray
                self.headerLabel = label
                
                self.attributeLabels = formattedAttributes.map { attributeDescription in
                    let iconLabel = UILabel()
                    iconLabel.text = "•"
                    iconLabel.font = Metrics.font
                    iconLabel.textColor = .darkGray
                    
                    let descriptionLabel = UILabel()
                    descriptionLabel.text = attributeDescription
                    descriptionLabel.font = Metrics.font
                    descriptionLabel.textColor = .darkGray
                    descriptionLabel.numberOfLines = 0
                    
                    return (iconLabel, descriptionLabel)
                }
            } else {
                self.headerLabel = nil
                self.attributeLabels = []
            }
            
            super.init(frame: .zero)
            
            headerLabel.map(addSubview)
            
            attributeLabels.forEach {
                addSubview($0)
                addSubview($1)
            }
        }
        
        /// Convenience initializer for attributed labels (backwards compatibility)
        convenience init(attributedLabel: NSAttributedString) {
            self.init(attributedString: attributedLabel, type: .label)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private Properties
        
        private let headerLabel: UILabel?
        
        private let attributeLabels: [(UILabel, UILabel)]
        
        // MARK: - UIView
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            guard let headerLabel else { return .zero }
            
            let headerHeight = headerLabel.sizeThatFits(size).height
            
            guard let (firstIconLabel, _) = attributeLabels.first else {
                return .init(width: max(size.width, 0), height: headerHeight)
            }
            
            let descriptionWidthToFit = [
                Metrics.attributeIconInset,
                firstIconLabel.sizeThatFits(size).width,
                Metrics.iconToDescriptionSpacing,
            ].reduce(size.width, -)
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)
            
            let height = attributeLabels
                .map { $1.sizeThatFits(descriptionSizeToFit).height }
                .reduce(headerHeight) {
                    $0 + Metrics.verticalSpacing + $1
                }
            
            return .init(width: size.width, height: height)
        }
        
        override func layoutSubviews() {
            guard let headerLabel else { return }
            
            headerLabel.bounds.size = headerLabel.sizeThatFits(bounds.size)
            headerLabel.frame.origin = .zero
            
            guard let (firstIconLabel, firstDescriptionLabel) = attributeLabels.first else {
                return
            }
            
            let firstPairYPosition = headerLabel.frame.maxY + Metrics.verticalSpacing
            
            firstIconLabel.sizeToFit()
            
            let descriptionWidthToFit = [
                Metrics.attributeIconInset,
                firstIconLabel.bounds.width,
                Metrics.iconToDescriptionSpacing,
            ].reduce(bounds.width, -)
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)
            
            firstDescriptionLabel.bounds.size = firstDescriptionLabel.sizeThatFits(descriptionSizeToFit)
            
            firstIconLabel.frame.origin = .init(x: Metrics.attributeIconInset, y: firstPairYPosition)
            
            let descriptionXPosition = firstIconLabel.frame.maxX + Metrics.iconToDescriptionSpacing
            
            firstDescriptionLabel.frame.origin = .init(x: descriptionXPosition, y: firstPairYPosition)
            
            let zippedAttributeLabels = zip(attributeLabels.dropFirst(), attributeLabels)
            for ((iconLabel, descriptionLabel), (_, previousDescriptionLabel)) in zippedAttributeLabels {
                iconLabel.sizeToFit()
                descriptionLabel.bounds.size = descriptionLabel.sizeThatFits(descriptionSizeToFit)
                
                let yPosition = previousDescriptionLabel.frame.maxY + Metrics.verticalSpacing
                
                iconLabel.frame.origin = .init(x: Metrics.attributeIconInset, y: yPosition)
                descriptionLabel.frame.origin = .init(x: descriptionXPosition, y: yPosition)
            }
        }
        
        // MARK: - Private Types
        
        private enum Metrics {
            
            static let verticalSpacing: CGFloat = 4
            static let attributeIconInset: CGFloat = 4
            static let iconToDescriptionSpacing: CGFloat = 4
            
            static let headerFont: UIFont = .italicSystemFont(ofSize: 11)
            static let font: UIFont = .monospacedSystemFont(ofSize: 10, weight: .regular)
        }
        
        // MARK: - Private Static Methods
        
        /// Formats accessibility-related attributes from an attributed string into human-readable descriptions.
        /// Focuses on attributes that impact accessibility, such as speech language, spell out, IPA notation, and punctuation.
        /// Filters out default language attributes that match the device's current locale.
        private static func formatAccessibilityAttributes(from attributedString: NSAttributedString) -> [String] {
            var descriptions: [String] = []
            
            let fullRange = NSRange(location: 0, length: attributedString.length)
            
            attributedString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
                let substring = (attributedString.string as NSString).substring(with: range)

                // Sort attributes by key name to ensure consistent ordering across test runs
                let sortedAttributes = attributes.sorted { $0.key.rawValue < $1.key.rawValue }
                
                for (key, value) in sortedAttributes {
                    // Check for accessibility speech language
                    if key == .accessibilitySpeechLanguage, let language = value as? String {
                        // SwiftUI attributed strings contain the locale even if it's the default locale, so we need to filter it out.
                        if !isDefaultLocaleLanguage(language) {
                            descriptions.append("\"\(substring)\": Language = \(language)")
                        }
                    }
                    
                    // Check for spell out attribute
                    if key == .accessibilitySpeechSpellOut {
                        let shouldSpellOut = (value as? Bool) ?? (value as? NSNumber)?.boolValue ?? false
                        if shouldSpellOut {
                            descriptions.append("\"\(substring)\": Spell Out")
                        }
                    }
                    
                    // Check for IPA notation
                    if key == .accessibilitySpeechIPANotation, let ipa = value as? String {
                        descriptions.append("\"\(substring)\": IPA = \(ipa)")
                    }

                    // Check for punctuation attribute
                    if key == .accessibilitySpeechPunctuation {
                        let shouldSpeakPunctuation = (value as? Bool) ?? (value as? NSNumber)?.boolValue ?? false
                        if shouldSpeakPunctuation {
                            descriptions.append("\"\(substring)\": Speak Punctuation")
                        }
                    }

                    // Check for pitch
                    if key == .accessibilitySpeechPitch, let pitch = value as? NSNumber {
                        descriptions.append("\"\(substring)\": Pitch = \(pitch)")
                    }
                    
                    // Check for heading level
                    if key == .accessibilityTextHeadingLevel, let level = value as? NSNumber {
                        let headingLevel = level.intValue
                        if headingLevel > 0 {
                            descriptions.append("\"\(substring)\": Heading Level = \(headingLevel)")
                        }
                    }
                }
            }
            
            return descriptions
        }
        
        /// Checks if the given language tag matches or is a variant of the device's current locale.
        /// For example, "en-Latn-US" would match device locale "en_US" or "en".
        /// This filters out system-added language attributes that match the user's preferred language.
        private static func isDefaultLocaleLanguage(_ languageTag: String) -> Bool {
            // Parse BCP 47 language tag manually (e.g., "en-Latn-US" -> ["en", "Latn", "US"])
            // The format is: language[-script][-region]
            let components = languageTag.components(separatedBy: "-")
            guard let tagLang = components.first?.lowercased(), !tagLang.isEmpty else {
                return false
            }
            
            // Get preferred languages list
            let preferredLanguages = Locale.preferredLanguages
            
            // Check if any preferred language starts with the same language code
            for preferredLang in preferredLanguages {
                let prefParts = preferredLang.lowercased().components(separatedBy: CharacterSet(charactersIn: "-_"))
                guard let prefLangCode = prefParts.first else { continue }
                
                // If the language codes match, consider it a default language
                // This is intentionally permissive - if the user's device is set to "en" anything,
                // we filter out "en-Latn-US", "en-US", etc. as they're all English variants
                if prefLangCode == tagLang {
                    return true
                }
            }
            
            return false
        }
    }
}

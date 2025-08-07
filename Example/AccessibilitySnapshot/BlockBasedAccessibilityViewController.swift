import Paralayout
import UIKit

@available(iOS 17.0, *)
final class BlockBasedAccessibilityViewController: AccessibilityViewController {
    
    private class TestView: UIView {
        let contentView = UIView()
        let descriptionLabel = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            contentView.backgroundColor = .systemBlue
            contentView.layer.cornerRadius = 8
            addSubview(contentView)
            
            descriptionLabel.font = .systemFont(ofSize: 14)
            descriptionLabel.numberOfLines = 0
            descriptionLabel.textColor = .darkText
            addSubview(descriptionLabel)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            contentView.frame = CGRect(x: 16, y: 8, width: 44, height: 44)
            
            let labelX = contentView.frame.maxX + 16
            let labelWidth = bounds.width - labelX - 16
            
            descriptionLabel.frame = CGRect(
                x: labelX,
                y: 8,
                width: labelWidth,
                height: bounds.height - 16
            )
        }
    }
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let views: [TestView] = (0..<8).map { _ in TestView() }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        
        scrollView.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        scrollView.addSubview(stackView)
        
        for testView in views {
            testView.heightAnchor.constraint(equalToConstant: 60).isActive = true
            stackView.addArrangedSubview(testView)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Block-Based Accessibility"
        
        // Test 1: Block properties taking precedence
        configureView(at: 0, description: "Block overrides:\nLabel, Value, and Hint") {
            $0.contentView.isAccessibilityElement = true
            $0.contentView.accessibilityLabel = "Regular Label"
            $0.contentView.accessibilityLabelBlock = { "Block Label" }
            $0.contentView.accessibilityValue = "Regular Value"
            $0.contentView.accessibilityValueBlock = { "Block Value" }
            $0.contentView.accessibilityHint = "Regular Hint"
            $0.contentView.accessibilityHintBlock = { "Block Hint" }
        }
        
        // Test 2: Block-based label only
        configureView(at: 1, description: "Block Label only:\nShould show 'Block Label'") {
            $0.contentView.isAccessibilityElement = true
            $0.contentView.accessibilityLabel = "Regular Label"
            $0.contentView.accessibilityLabelBlock = { "Block Label" }
        }
        
        // Test 3: Block-based value only
        configureView(at: 2, description: "Block Value only:\nShould show 'Block Value'") {
            $0.contentView.isAccessibilityElement = true
            $0.contentView.accessibilityValue = "Regular Value"
            $0.contentView.accessibilityValueBlock = { "Block Value" }
        }
        
        // Test 4: Block-based hint only
        configureView(at: 3, description: "Block Hint only:\nShould show 'Block Hint'") {
            $0.contentView.isAccessibilityElement = true
            $0.contentView.accessibilityHint = "Regular Hint"
            $0.contentView.accessibilityHintBlock = { "Block Hint" }
        }
        
        // Test 5: Dynamic block values
        var counter = 0
        configureView(at: 4, description: "Dynamic Label:\nIncreases on each access") {
            $0.contentView.isAccessibilityElement = true
            $0.contentView.accessibilityLabelBlock = {
                counter += 1
                return "Access count: \(counter)"
            }
        }
        
        // Test 6: Nil-returning blocks
        configureView(at: 5, description: "Nil blocks:\nShould fall back to regular values") {
            $0.contentView.isAccessibilityElement = true
            $0.contentView.accessibilityLabel = "Fallback Label"
            $0.contentView.accessibilityLabelBlock = { nil }
            $0.contentView.accessibilityValue = "Fallback Value"
            $0.contentView.accessibilityValueBlock = { nil }
            $0.contentView.accessibilityHint = "Fallback Hint"
            $0.contentView.accessibilityHintBlock = { nil }
        }
        
        // Test 7: Traits
        configureView(at: 6, description: "Traits Test:\nShould be Link, not Button") {
            $0.contentView.isAccessibilityElement = true
            $0.contentView.accessibilityLabel = "Traits Test"
            $0.contentView.accessibilityTraits = .button
            $0.contentView.accessibilityTraitsBlock = { .link }
        }
        
        // Test 8: Frame and activation point
        configureView(at: 7, description: "Frame & Activation:\nCustom frame and activation point") {
            $0.contentView.isAccessibilityElement = true
            $0.contentView.accessibilityLabel = "Frame Test"
            $0.contentView.accessibilityFrameBlock = {
                // Offset from actual frame for testing
                let frame = $0.contentView.frame
                return CGRect(
                    x: frame.minX + 20,
                    y: frame.minY + 20,
                    width: frame.width,
                    height: frame.height
                )
            }
            $0.contentView.accessibilityActivationPointBlock = {
                let center = $0.contentView.center
                return CGPoint(x: center.x + 20, y: center.y + 20)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let safeArea = view.safeAreaLayoutGuide
        scrollView.frame = safeArea.layoutFrame
        
        let contentWidth = scrollView.bounds.width
        stackView.frame = CGRect(
            x: 16,
            y: 16,
            width: contentWidth - 32,
            height: stackView.systemLayoutSizeFitting(
                CGSize(width: contentWidth - 32, height: .greatestFiniteMagnitude)
            ).height
        )
        
        scrollView.contentSize = CGSize(
            width: contentWidth,
            height: stackView.frame.maxY + 16
        )
    }
    
    private func configureView(at index: Int, description: String, configuration: (TestView) -> Void) {
        let testView = views[index]
        testView.descriptionLabel.text = description
        configuration(testView)
    }
}

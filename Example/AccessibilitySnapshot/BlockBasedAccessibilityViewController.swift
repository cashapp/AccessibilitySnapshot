import Paralayout
import UIKit

@available(iOS 17.0, *)
final class BlockBasedAccessibilityViewController: AccessibilityViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .systemBackground
        scrollView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        return scrollView
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        stack.distribution = .fill
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()
    
    // Create a row view that contains a circle and label
    private func createRow(circle: UIView, label: UILabel) -> UIView {
        let row = UIView()
        row.backgroundColor = .clear
        
        // Configure circle
        circle.backgroundColor = .systemGray5
        circle.layer.cornerRadius = 15
        circle.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure label
        label.textColor = .label
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Add shadow to circle
        circle.layer.shadowColor = UIColor.black.cgColor
        circle.layer.shadowOffset = CGSize(width: 0, height: 1)
        circle.layer.shadowOpacity = 0.1
        circle.layer.shadowRadius = 2
        
        row.addSubview(circle)
        row.addSubview(label)
        
        NSLayoutConstraint.activate([
            // Circle constraints
            circle.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            circle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: 30),
            circle.heightAnchor.constraint(equalToConstant: 30),
            
            // Label constraints
            label.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            label.topAnchor.constraint(equalTo: row.topAnchor),
            label.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])
        
        return row
    }
    
    private let views = (0..<8).map { _ in UIView() }
    private let labels = (0..<8).map { _ in UILabel() }
    
    override func loadView() {
        super.loadView()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Set up scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up container and stack view
        scrollView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container view constraints
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Stack view constraints
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Create and add rows to stack view
        for (circle, label) in zip(views, labels) {
            let row = createRow(circle: circle, label: label)
            stackView.addArrangedSubview(row)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure accessibility
        for view in views {
            view.isAccessibilityElement = true
        }
        
        for label in labels {
            label.isAccessibilityElement = false
        }
        
        // View with block-based properties taking precedence
        views[0].accessibilityLabel = "Regular Label"
        views[0].accessibilityLabelBlock = { "Block Label" }
        views[0].accessibilityValue = "Regular Value"
        views[0].accessibilityValueBlock = { "Block Value" }
        views[0].accessibilityHint = "Regular Hint"
        views[0].accessibilityHintBlock = { "Block Hint" }
        labels[0].text = "View 1: Shows block-based properties taking precedence over regular properties"
        
        // View with block-based label only
        views[1].accessibilityLabel = "Regular Label"
        views[1].accessibilityLabelBlock = { "Block Label" }
        labels[1].text = "View 2: Demonstrates block-based label overriding regular label"
        
        // View with block-based value only
        views[2].accessibilityValue = "Regular Value"
        views[2].accessibilityValueBlock = { "Block Value" }
        labels[2].text = "View 3: Shows block-based value overriding regular value"
        
        // View with block-based hint only
        views[3].accessibilityHint = "Regular Hint"
        views[3].accessibilityHintBlock = { "Block Hint" }
        labels[3].text = "View 4: Demonstrates block-based hint overriding regular hint"
        
        // View with dynamic block values
        var counter = 0
        views[4].accessibilityLabelBlock = {
            counter += 1
            return "Dynamic Label \(counter)"
        }
        labels[4].text = "View 5: Shows dynamic block values that change on each access"
        
        views[5].accessibilityLabel = "Fallback Label"
        views[5].accessibilityLabelBlock = { nil }
        views[5].accessibilityValue = "Fallback Value"
        views[5].accessibilityValueBlock = { nil }
        views[5].accessibilityHint = "Fallback Hint"
        views[5].accessibilityHintBlock = { nil }
        labels[5].text = "View 6: Demonstrates blocks do NOT fallback to regular properties when blocks return nil"
        
        // View testing traits
        views[6].accessibilityTraits = .button
        views[6].accessibilityTraitsBlock = { .link }
        views[6].accessibilityLabel = "Traits Test"
        labels[6].text = "View 7: Tests accessibility traits (button trait overridden by link trait)"
        
        // View testing frame and activation point
        views[7].accessibilityLabel = "Frame Test"
        views[7].accessibilityFrameBlock = {
            CGRect(x: 50, y: 50, width: 100, height: 100)
        }
        views[7].accessibilityActivationPointBlock = {
            CGPoint(x: 75, y: 75)
        }
        labels[7].text = "View 8: Tests custom accessibility frame and activation point"
    }
}

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
    
    // Create a grid of circles
    private func createCircleGrid() -> UIView {
        let gridView = UIView()
        gridView.backgroundColor = .clear
        
        let circleSize: CGFloat = 30
        let spacing: CGFloat = 20
        let circlesPerRow = 4
        
        // Create circles for each overrideable property
        let properties = [
            "Label",
            "Value",
            "Hint",
            "Traits",
            "Frame",
            "ActivationPoint",
            "Identifier",
            "CustomActions",
        ]
        
        for (index, string) in properties.enumerated() {
            let circle = UIView()
            circle.backgroundColor = .lightGray
            circle.layer.cornerRadius = circleSize / 2
            circle.translatesAutoresizingMaskIntoConstraints = false
            
            // Add shadow
            circle.layer.shadowColor = UIColor.black.cgColor
            circle.layer.shadowOffset = CGSize(width: 0, height: 1)
            circle.layer.shadowOpacity = 0.1
            circle.layer.shadowRadius = 2
            
            gridView.addSubview(circle)
            
            // Calculate position
            let row = index / circlesPerRow
            let col = index % circlesPerRow
            
            NSLayoutConstraint.activate([
                circle.widthAnchor.constraint(equalToConstant: circleSize),
                circle.heightAnchor.constraint(equalToConstant: circleSize),
                circle.leadingAnchor.constraint(equalTo: gridView.leadingAnchor, constant: CGFloat(col) * (circleSize + spacing)),
                circle.topAnchor.constraint(equalTo: gridView.topAnchor, constant: CGFloat(row) * (circleSize + spacing))
            ])
            
            // Make circle accessible
            circle.isAccessibilityElement = true
            circle.accessibilityLabel = properties[index]
            
            // Store circle for later use
            circles.append(circle)
        }
        
        // Add size constraints to grid
        let rows = (properties.count + circlesPerRow - 1) / circlesPerRow
        NSLayoutConstraint.activate([
            gridView.heightAnchor.constraint(equalToConstant: CGFloat(rows) * (circleSize + spacing) - spacing)
        ])
        
        return gridView
    }
    
    private var circles: [UIView] = []
    
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
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Add circle grid
        let gridView = createCircleGrid()
        stackView.addArrangedSubview(gridView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure accessibility for each circle
        guard circles.count >= 8 else { return }
        
        // Circle 1: Label Block
        circles[0].accessibilityLabel = "Regular Label"
        circles[0].accessibilityLabelBlock = { "Block Label" }
        
        // Circle 2: Value Block
        circles[1].accessibilityValue = "Regular Value"
        circles[1].accessibilityValueBlock = { "Block Value" }
        
        // Circle 3: Hint Block
        circles[2].accessibilityHint = "Regular Hint"
        circles[2].accessibilityHintBlock = { "Block Hint" }
        
        // Circle 4: Traits Block
        circles[3].accessibilityTraits = .button
        circles[3].accessibilityTraitsBlock = { .link }
        
        // Circle 5: Frame Block
        circles[4].accessibilityFrameBlock = {
            CGRect(x: 10, y: 50, width: 200, height: 100)
        }
        
        // Circle 6: Activation Point Block
        circles[5].accessibilityActivationPointBlock = {
            CGPoint(x: 110, y: 100)
        }
        
        // Circle 7: Identifier
        circles[6].accessibilityIdentifier = "Regular Identifier"
        circles[6].accessibilityIdentifierBlock = {
            "Block Identifier"
        }
        
        // Circle 8: Custom Actions Block
        let customAction = UIAccessibilityCustomAction(name: "Custom Action") { _ in true }
        circles[7].accessibilityCustomActions = [customAction]
        circles[7].accessibilityCustomActionsBlock = {
            [UIAccessibilityCustomAction(name: "Block Custom Action") { _ in true }]
        }
    }
}

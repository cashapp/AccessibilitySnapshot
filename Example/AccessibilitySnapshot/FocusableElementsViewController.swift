import UIKit

/// A view controller that demonstrates focusable elements for testing focus overlay snapshots.
/// Based on Apple's WWDC21-10260 "Focus on iPad Keyboard Navigation" sample code.
@available(iOS 14.0, *)
final class FocusableElementsViewController: AccessibilityViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
{
    // MARK: - Private Properties

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var gridCollectionView: UICollectionView!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }

    // MARK: - Private Methods

    private func setUpUI() {
        view.backgroundColor = .systemBackground

        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])

        // Add title
        let titleLabel = UILabel()
        titleLabel.text = "Focusable Elements"
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Use Tab key to navigate between elements"
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        stackView.addArrangedSubview(subtitleLabel)

        // Add focusable elements
        addLabeledElement(label: "Search", element: createSearchBar())
        addLabeledElement(label: "Grid", element: createGridCollectionView())
        addLabeledElement(label: "Button", element: createButton())
        addLabeledElement(label: "Switch", element: createSwitch())
        addLabeledElement(label: "Segmented Control", element: createSegmentedControl())
        addLabeledElement(label: "Slider", element: createSlider())
    }

    private func addLabeledElement(label: String, element: UIView) {
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 8
        containerStack.alignment = .fill

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .preferredFont(forTextStyle: .headline)
        labelView.textColor = .label

        containerStack.addArrangedSubview(labelView)
        containerStack.addArrangedSubview(element)

        stackView.addArrangedSubview(containerStack)
    }

    private func createSearchBar() -> UIView {
        // Wrap search bar in a container with its own focus group
        let container = UIView()
        
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search..."
        searchBar.searchBarStyle = .minimal
        searchBar.accessibilityLabel = "Search field"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: container.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        // Put the search bar in its own focus group so Tab can navigate to/from it
        if #available(iOS 15.0, *) {
            container.focusGroupIdentifier = "com.example.focusable.search"
        }
        
        return container
    }

    private func createButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Submit", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.accessibilityLabel = "Submit button"
        button.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        return button
    }

    @objc private func submitButtonTapped() {
        print("Submit button pressed")
    }

    private func createSwitch() -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let toggle = UISwitch()
        toggle.isOn = true
        toggle.accessibilityLabel = "Enable notifications"

        let label = UILabel()
        label.text = "Enable notifications"
        label.font = .preferredFont(forTextStyle: .body)

        container.addArrangedSubview(toggle)
        container.addArrangedSubview(label)
        container.addArrangedSubview(UIView()) // Spacer

        return container
    }

    private func createSegmentedControl() -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: ["Option A", "Option B", "Option C"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.accessibilityLabel = "Options selector"
        return segmentedControl
    }

    private func createSlider() -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let minLabel = UILabel()
        minLabel.text = "0"
        minLabel.font = .preferredFont(forTextStyle: .caption1)

        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50
        slider.accessibilityLabel = "Volume slider"

        let maxLabel = UILabel()
        maxLabel.text = "100"
        maxLabel.font = .preferredFont(forTextStyle: .caption1)

        container.addArrangedSubview(minLabel)
        container.addArrangedSubview(slider)
        container.addArrangedSubview(maxLabel)

        // Make slider expand to fill space
        slider.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return container
    }

    private func createGridCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12

        gridCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        gridCollectionView.backgroundColor = .clear
        gridCollectionView.translatesAutoresizingMaskIntoConstraints = false
        gridCollectionView.dataSource = self
        gridCollectionView.delegate = self

        // Enable focus for keyboard navigation (per WWDC21-10260)
        if #available(iOS 15.0, *) {
            gridCollectionView.allowsFocus = true
        }

        gridCollectionView.register(GridCell.self, forCellWithReuseIdentifier: GridCell.reuseIdentifier)

        // Fixed height for 2x2 grid
        gridCollectionView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        return gridCollectionView
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridCell.reuseIdentifier, for: indexPath) as! GridCell
        let isFocusable = self.collectionView(collectionView, canFocusItemAt: indexPath)
        let itemNumber = indexPath.item + 1
        // Item 1 is not accessible
        let isAccessibilityElement = itemNumber != 1
        cell.configure(with: itemNumber, isAccessibilityElement: isAccessibilityElement, isFocusable: isFocusable)
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Item \(indexPath.item + 1) pressed")
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        let itemNumber = indexPath.item + 1
        return itemNumber == 2 || itemNumber == 4
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 12) / 2
        return CGSize(width: width, height: 50)
    }
}

// MARK: - GridCell

@available(iOS 14.0, *)
private final class GridCell: UICollectionViewCell {
    static let reuseIdentifier = "GridCell"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .systemGray5
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray3.cgColor

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .systemBlue

        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func configure(with index: Int, isAccessibilityElement: Bool, isFocusable: Bool) {
        let title = "Item \(index)"
        let subtitle: String? = [
            isFocusable ? nil : "Not focusable",
            isAccessibilityElement ? nil : "Not accessible"
        ].compactMap { $0 }
            .joined(separator: " | ")
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        self.isAccessibilityElement = isAccessibilityElement
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        if isFocused {
            contentView.backgroundColor = .systemBlue
            titleLabel.textColor = .white
            subtitleLabel.textColor = .white.withAlphaComponent(0.8)
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
            contentView.layer.borderWidth = 4.0
        } else {
            contentView.backgroundColor = .systemGray5
            titleLabel.textColor = .systemBlue
            subtitleLabel.textColor = .secondaryLabel
            contentView.layer.borderColor = UIColor.systemGray3.cgColor
            contentView.layer.borderWidth = 1.0
        }
    }
}

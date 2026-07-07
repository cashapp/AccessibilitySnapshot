import UIKit

final class CollectionViewAccessibilityViewController: AccessibilityViewController {
    enum ScrollPosition {
        case top, middle, bottom
    }

    private let scrollPosition: ScrollPosition
    private let cellCount = 30

    init(scrollPosition: ScrollPosition) {
        self.scrollPosition = scrollPosition
        super.init(nibName: nil, bundle: nil)
        title = "Collection (\(scrollPosition))"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 375, height: 44)
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.register(LabelCell.self, forCellWithReuseIdentifier: "cell")
        cv.backgroundColor = .systemBackground
        return cv
    }()

    override func loadView() {
        view = collectionView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToPosition()
    }

    private func scrollToPosition() {
        let indexPath: IndexPath
        let position: UICollectionView.ScrollPosition
        switch scrollPosition {
        case .top:
            indexPath = IndexPath(item: 0, section: 0)
            position = .top
        case .middle:
            indexPath = IndexPath(item: cellCount / 2, section: 0)
            position = .centeredVertically
        case .bottom:
            indexPath = IndexPath(item: cellCount - 1, section: 0)
            position = .bottom
        }
        collectionView.scrollToItem(at: indexPath, at: position, animated: false)
    }
}

extension CollectionViewAccessibilityViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cellCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! LabelCell
        cell.label.text = "Item \(indexPath.item)"
        cell.accessibilityLabel = "Item \(indexPath.item)"
        cell.isAccessibilityElement = true
        return cell
    }
}

private final class LabelCell: UICollectionViewCell {
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

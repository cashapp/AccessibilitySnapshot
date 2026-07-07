import UIKit

final class ScrollViewAccessibilityViewController: AccessibilityViewController {
    enum ScrollPosition {
        case top, middle, bottom
    }

    private let scrollPosition: ScrollPosition
    private let cellCount = 30

    init(scrollPosition: ScrollPosition) {
        self.scrollPosition = scrollPosition
        super.init(nibName: nil, bundle: nil)
        title = "Scroll (\(scrollPosition))"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()

    override func loadView() {
        view = tableView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToPosition()
    }

    private func scrollToPosition() {
        switch scrollPosition {
        case .top:
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        case .middle:
            tableView.scrollToRow(at: IndexPath(row: cellCount / 2, section: 0), at: .middle, animated: false)
        case .bottom:
            tableView.scrollToRow(at: IndexPath(row: cellCount - 1, section: 0), at: .bottom, animated: false)
        }
    }
}

extension ScrollViewAccessibilityViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cellCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        cell.accessibilityLabel = "Row \(indexPath.row)"
        return cell
    }
}

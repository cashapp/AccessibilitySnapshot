//
//  Copyright 2019 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Paralayout
import UIKit

@available(iOS 11, *)
final class DataTableViewController: AccessibilityViewController {

    // MARK: - Public Types

    enum Configuration {
        case basic
        case withHeaders
        case undefinedRows
        case undefinedColumns
        case undefinedRowsAndColumns
    }

    // MARK: - Life Cycle

    init(configuration: Configuration) {
        self.configuration = configuration

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let configuration: Configuration

    // MARK: - UIViewController

    override func loadView() {
        switch configuration {
        case .basic:
            self.view = View()

        case .withHeaders:
            self.view = ViewWithHeaders(definesRows: true, definesColumns: true)

        case .undefinedRows:
            self.view = ViewWithHeaders(definesRows: false, definesColumns: true)

        case .undefinedColumns:
            self.view = ViewWithHeaders(definesRows: true, definesColumns: false)

        case .undefinedRowsAndColumns:
            self.view = ViewWithHeaders(definesRows: false, definesColumns: false)
        }
    }

}

// MARK: -

@available(iOS 11, *)
private extension DataTableViewController {

    class View: UIView, UIAccessibilityContainerDataTable {

        // MARK: - Life Cycle

        convenience init() {
            let dataCells: [Cell] = [
                .init(row: 0, column: 0, width: 1, height: 1, label: "A1"),
                .init(row: 0, column: 1, width: 1, height: 1, label: "B1"),
                .init(row: 0, column: 2, width: 1, height: 1, label: "C1"),
                .init(row: 0, column: 3, width: 1, height: 1, label: "D1"),
                .init(row: 1, column: 0, width: 1, height: 1, label: "A2"),
                .init(row: 1, column: 1, width: 2, height: 1, label: "B2"),
                .init(row: 1, column: 3, width: 1, height: 1, label: "D2"),
                .init(row: 2, column: 0, width: 1, height: 1, label: "A3"),
                .init(row: 2, column: 1, width: 1, height: 2, label: "B3"),
                .init(row: 2, column: 2, width: 1, height: 1, label: "C3"),
                .init(row: 2, column: 3, width: 1, height: 1, label: "D3"),
                .init(row: 3, column: 0, width: 1, height: 2, label: "A4"),
                .init(row: 3, column: 2, width: 2, height: 2, label: "C4"),
                .init(row: 4, column: 1, width: 1, height: 1, label: "B5"),
            ]

            self.init(dataCells: dataCells)
        }

        init(dataCells: [Cell]) {
            self.dataCells = dataCells

            self.cellsByIndex = Dictionary(
                dataCells.map { (IndexPath(row: $0.row, section: $0.column), $0) },
                uniquingKeysWith: { first, _ in first }
            )

            super.init(frame: .zero)

            let lastCell = dataCells.last!
            lastCell.accessibilityValue = "Value"
            lastCell.accessibilityHint = "Hint"
            lastCell.accessibilityTraits.insert(.notEnabled)
            lastCell.accessibilityTraits.insert(.button)
            lastCell.accessibilityTraits.insert(.header)
            lastCell.accessibilityTraits.insert(.link)
            lastCell.accessibilityTraits.insert(.adjustable)
            lastCell.accessibilityTraits.insert(.image)
            lastCell.accessibilityTraits.insert(.searchField)

            dataCells.forEach(addSubview)

            notACell.text = "Hello World"
            addSubview(notACell)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let dataCells: [Cell]

        // MARK: - Private Properties

        private let notACell: UILabel = .init()

        private var cellsByIndex: [IndexPath: Cell]

        // MARK: - UIView

        override func layoutSubviews() {
            let layoutBounds = AspectRatio(
                width: CGFloat(accessibilityColumnCount()),
                height: CGFloat(accessibilityRowCount())
            ).rect(
                toFit: bounds.inset(left: 20, top: 20, right: 20, bottom: 20),
                at: .center,
                in: self
            )

            let cellSize = CGSize(
                width: layoutBounds.width / CGFloat(accessibilityColumnCount()),
                height: layoutBounds.height / CGFloat(accessibilityRowCount())
            )

            dataCells.forEach { cell in
                cell.frame = .init(
                    x: layoutBounds.minX + CGFloat(cell.column) * cellSize.width,
                    y: layoutBounds.minY + CGFloat(cell.row) * cellSize.height,
                    width: CGFloat(cell.width) * cellSize.width,
                    height: CGFloat(cell.height) * cellSize.height
                )
            }

            notACell.sizeToFit()
            notACell.alignToSuperview(.topCenter, inset: 60)
        }

        // MARK: - UIAccessibility

        override var accessibilityContainerType: UIAccessibilityContainerType {
            get {
                return .dataTable
            }
            set {
                // No-op.
            }
        }

        // MARK: - UIAccessibilityContainerDataTable

        func accessibilityDataTableCellElement(forRow row: Int, column: Int) -> UIAccessibilityContainerDataTableCell? {
            return cellsByIndex[IndexPath(row: row, section: column)]
        }

        func accessibilityRowCount() -> Int {
            return 5
        }

        func accessibilityColumnCount() -> Int {
            return 4
        }

    }

}

// MARK: -

@available(iOS 11, *)
private extension DataTableViewController {

    final class ViewWithHeaders: View {

        init(definesRows: Bool, definesColumns: Bool) {
            var dataCells: [Cell] = []

            for row in 0..<6 {
                for column in 0..<6 {
                    let columnName = ["A","B","C","D","E","F"][column]
                    dataCells.append(.init(
                        row: row,
                        column: column,
                        accessibilityRow: definesRows ? row : NSNotFound,
                        accessibilityColumn: definesColumns ? column : NSNotFound,
                        width: 1,
                        height: 1,
                        label: "\(columnName)\(row+1)",
                        value: "\(columnName)\(row+1) Value"
                    ))
                }
            }

            super.init(dataCells: dataCells)
        }

        // MARK: - UIAccessibilityContainerDataTable

        override func accessibilityRowCount() -> Int {
            return 6
        }

        override func accessibilityColumnCount() -> Int {
            return 6
        }

        func accessibilityHeaderElements(forRow row: Int) -> [UIAccessibilityContainerDataTableCell]? {
            return [
                dataCells.first(where: { $0.row == row && $0.column == 0 }),
                dataCells.first(where: { $0.row == row && $0.column == 1 }),
                dataCells.first(where: { $0.row == row && $0.column == 2 }),
            ].compactMap { $0 }
        }

        func accessibilityHeaderElements(forColumn column: Int) -> [UIAccessibilityContainerDataTableCell]? {
            return [
                dataCells.first(where: { $0.column == column && $0.row == 0 }),
                dataCells.first(where: { $0.column == column && $0.row == 1 }),
                dataCells.first(where: { $0.column == column && $0.row == 2 }),
            ].compactMap { $0 }
        }

    }

}

// MARK: -

@available(iOS 11, *)
private extension DataTableViewController {

    final class Cell: UIView, UIAccessibilityContainerDataTableCell {

        // MARK: - Life Cycle

        init(
            row: Int,
            column: Int,
            accessibilityRow: Int? = nil,
            accessibilityColumn: Int? = nil,
            width: Int,
            height: Int,
            label: String,
            value: String? = nil
        ) {
            self.row = row
            self.accessibilityRow = accessibilityRow ?? row
            self.column = column
            self.accessibilityColumn = accessibilityColumn ?? column
            self.width = width
            self.height = height

            super.init(frame: .zero)

            layer.borderColor = UIColor.lightGray.cgColor
            layer.borderWidth = 1

            isAccessibilityElement = true
            accessibilityLabel = label
            accessibilityValue = value
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let row: Int

        let accessibilityRow: Int

        let column: Int

        let accessibilityColumn: Int

        let width: Int

        let height: Int

        // MARK: - UIAccessibilityContainerDataTableCell

        func accessibilityRowRange() -> NSRange {
            return NSRange(location: accessibilityRow, length: height)
        }

        func accessibilityColumnRange() -> NSRange {
            return NSRange(location: accessibilityColumn, length: width)
        }

    }

}

// MARK: -

@available(iOS 11, *)
extension DataTableViewController {

    static func makeConfigurationSelectionViewController(
        presentingViewController: UIViewController
    ) -> UIViewController {
        func selectConfiguration(_ configuration: DataTableViewController.Configuration) {
            let viewController = DataTableViewController(configuration: configuration)
            presentingViewController.present(viewController, animated: true, completion: nil)
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(.init(title: "Basic", style: .default, handler: { _ in
            selectConfiguration(.basic)
        }))

        alertController.addAction(.init(title: "With Headers", style: .default, handler: { _ in
            selectConfiguration(.withHeaders)
        }))

        alertController.addAction(.init(title: "Undefined Rows", style: .default, handler: { _ in
            selectConfiguration(.undefinedRows)
        }))

        alertController.addAction(.init(title: "Undefined Columns", style: .default, handler: { _ in
            selectConfiguration(.undefinedColumns)
        }))

        alertController.addAction(.init(title: "Undefined Rows and Columns", style: .default, handler: { _ in
            selectConfiguration(.undefinedRowsAndColumns)
        }))

        return alertController
    }

}

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

import AccessibilitySnapshot
import UIKit
import XCTest

final class AccessibilityHierarchyParserTests: XCTestCase {
    
    func testUserInterfaceLayoutDirection() {
        let gridView = UIView(frame: .init(x: 0, y: 0, width: 20, height: 20))
        
        let elementA = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
        elementA.isAccessibilityElement = true
        elementA.accessibilityLabel = "A"
        elementA.accessibilityFrame = elementA.frame
        gridView.addSubview(elementA)
        
        let elementB = UIView(frame: .init(x: 10, y: 0, width: 10, height: 10))
        elementB.isAccessibilityElement = true
        elementB.accessibilityLabel = "B"
        elementB.accessibilityFrame = elementB.frame
        gridView.addSubview(elementB)
        
        let elementC = UIView(frame: .init(x: 0, y: 10, width: 10, height: 10))
        elementC.isAccessibilityElement = true
        elementC.accessibilityLabel = "C"
        elementC.accessibilityFrame = elementC.frame
        gridView.addSubview(elementC)
        
        let elementD = UIView(frame: .init(x: 10, y: 10, width: 10, height: 10))
        elementD.isAccessibilityElement = true
        elementD.accessibilityLabel = "D"
        elementD.accessibilityFrame = elementD.frame
        gridView.addSubview(elementD)
        
        let parser = AccessibilityHierarchyParser()
        
        let ltrElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).map { $0.description }
        XCTAssertEqual(ltrElements, ["A", "B", "C", "D"])
        
        let rtlElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .rightToLeft),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).map { $0.description }
        XCTAssertEqual(rtlElements, ["B", "A", "D", "C"])
    }
    
    
    
    
    func testVerticalSeperation() {
        let magicNumber = 8.0 // This is enough to trigger vertical separation for phone but not for pad
        
        let gridView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 20))
        
        let elementA = UIView(frame: .init(x: 0, y: magicNumber, width: 10, height: 10))
        elementA.isAccessibilityElement = true
        elementA.accessibilityLabel = "A"
        elementA.accessibilityFrame = elementA.frame
        gridView.addSubview(elementA)
        
        let elementB = UIView(frame: .init(x: 10, y: 0, width: 0, height: 10))
        elementB.isAccessibilityElement = true
        elementB.accessibilityLabel = "B"
        elementB.accessibilityFrame = elementB.frame
        gridView.addSubview(elementB)
        
        let elementC = UIView(frame: .init(x: 20, y: -(magicNumber), width: 10, height: 10))
        elementC.isAccessibilityElement = true
        elementC.accessibilityLabel = "C"
        elementC.accessibilityFrame = elementC.frame
        gridView.addSubview(elementC)
        
        let elementD = UIView(frame: .init(x: 30, y: -(magicNumber), width: 10, height: 10))
        elementD.isAccessibilityElement = true
        elementD.accessibilityLabel = "D"
        elementD.accessibilityFrame = elementD.frame
        gridView.addSubview(elementD)
        
        let parser = AccessibilityHierarchyParser()
        
        let padElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
                TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .pad)
        ).map { $0.description }
        // on pad elements are sorted horizontally
        XCTAssertEqual(padElements, ["A", "B", "C", "D"])
        
        let phoneElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
                TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).map { $0.description }
        // on phone elements are sorted vertically and then left to right
        XCTAssertEqual(phoneElements, ["C", "D", "B", "A"])
        
        
        let padMagicNumber = 25
        
        elementA.accessibilityFrame = .init(x: 0, y: padMagicNumber, width: 10, height: 10)
        elementB.accessibilityFrame = .init(x: 10, y: 0, width: 0, height: 10)
        elementC.accessibilityFrame = .init(x: 20, y: -(padMagicNumber), width: 10, height: 10)
        elementD.accessibilityFrame = .init(x: 30, y: -(padMagicNumber), width: 10, height: 10)
        
        
        
        let padAgain = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider:
                TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .pad)
        ).map { $0.description }
        
        
        // Now pad elements are sorted vertically and then left to right
        XCTAssertEqual(padAgain, ["C", "D", "B", "A"])

    }
    
    func testUITableView() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        
        let dataSource = SimpleTableDataSource()
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        let headerLabel = UILabel()
        headerLabel.text = "Table Header"
        headerLabel.frame = headerView.bounds
        headerView.addSubview(headerLabel)
        tableView.tableHeaderView = headerView
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        let footerLabel = UILabel()
        footerLabel.text = "Table Footer"
        footerLabel.frame = footerView.bounds
        footerView.addSubview(footerLabel)
        tableView.tableFooterView = footerView
        
        tableView.reloadData()
        tableView.layoutIfNeeded()
        
        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityElements(
            in: tableView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).map { $0.description }
        let correctLabels = [
            "Table Header",
            "Section 0 Header",
            "Cell 0",
            "Cell 1",
            "Section 0 Footer",
            "Section 1 Header",
            "Cell 0",
            "Cell 1",
            "Section 1 Footer",
            "Table Footer"
        ]

        XCTAssertEqual(elements, correctLabels)
    }
    
    func testUICollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 300, height: 400), collectionViewLayout: layout)
        
        let dataSource = SimpleCollectionDataSource()
        collectionView.dataSource = dataSource
        collectionView.delegate = dataSource
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SupplementaryView")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SupplementaryView")
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        
        let parser = AccessibilityHierarchyParser()
        let elements = parser.parseAccessibilityElements(
            in: collectionView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight),
            userInterfaceIdiomProvider: TestUserInterfaceIdiomProvider(userInterfaceIdiom: .phone)
        ).map { $0.description }
        let correctLabels = [
            "Collection Section 0 Header",
            "Collection Cell 0",
            "Collection Cell 1",
            "Collection Section 0 Footer",
            "Collection Section 1 Header",
            "Collection Cell 0",
            "Collection Cell 1",
            "Collection Section 1 Footer",
        ]

        XCTAssertEqual(elements, correctLabels)
    }
}

// MARK: -

private struct TestUserInterfaceLayoutDirectionProvider: UserInterfaceLayoutDirectionProviding {

    var userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection

}

private struct TestUserInterfaceIdiomProvider: UserInterfaceIdiomProviding {

    var userInterfaceIdiom: UIUserInterfaceIdiom
    
}

// MARK: - Simple Data Sources for Testing

private class SimpleTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Cell \(indexPath.row)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        headerView.accessibilityLabel = "Section \(section) Header"
        headerView.isAccessibilityElement = true
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        footerView.accessibilityLabel = "Section \(section) Footer"
        footerView.isAccessibilityElement = true
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44
    }
}

private class SimpleCollectionDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        let label = UILabel()
        label.text = "Collection Cell \(indexPath.item)"
        label.frame = cell.bounds
        cell.contentView.addSubview(label)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SupplementaryView", for: indexPath)
        let label = UILabel()
        
        if kind == UICollectionView.elementKindSectionHeader {
            label.text = "Collection Section \(indexPath.section) Header"
        } else if kind == UICollectionView.elementKindSectionFooter {
            label.text = "Collection Section \(indexPath.section) Footer"
        }
        
        label.frame = view.bounds
        view.addSubview(label)
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
}


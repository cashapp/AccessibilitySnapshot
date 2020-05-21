//
//  HeadlessSnapshotTests.swift
//  HeadlessSnapshotTests
//
//  Created by Nicholas Entin on 5/20/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import AccessibilitySnapshot

final class HeadlessSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()

        self.recordMode = true
    }

    func testExample() {
        let view = View()
        view.bounds.size = CGSize(width: 100, height: 100)
        view.layoutIfNeeded()

        SnapshotVerifyAccessibility(view)
    }

}

// MARK: -

private final class View: UIView {

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.text = "Hello world"
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let label: UILabel = .init()

    // MARK: - UIView

    override func layoutSubviews() {
        label.sizeToFit()
        label.center = CGPoint(x: 50, y: 50)
    }

}

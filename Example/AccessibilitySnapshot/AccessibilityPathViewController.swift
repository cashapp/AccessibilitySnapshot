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

final class AccessibilityPathViewController: AccessibilityViewController {

    // MARK: - Life Cycle

    init() {
        views = [
            AccessibilityPathView(relativePath: UIBezierPath(
                roundedRect: CGRect(x: 0, y: 0, width: 60, height: 40),
                cornerRadius: 20
            )),
            AccessibilityPathView(relativePath: UIBezierPath(
                arcCenter: CGPoint(x: 30, y: 20),
                radius: 20,
                startAngle: 0,
                endAngle: 1.57,
                clockwise: true
            )),
            AccessibilityPathView(relativePath: UIBezierPath(
                ovalIn: CGRect(x: 0, y: 0, width: 60, height: 40)
            )),
            AccessibilityPathView(relativePath: UIBezierPath(
                cgPath: {
                    let path = CGMutablePath()
                    path.move(to: .zero)
                    path.addQuadCurve(
                        to: .init(x: 60, y: 40),
                        control: .init(x: 15, y: 30)
                    )
                    return path
                }()
            )),
            AccessibilityPathView(relativePath: UIBezierPath(
                cgPath: {
                    let path = CGMutablePath()
                    path.move(to: CGPoint(x: 0, y: 40))
                    path.addLine(to: CGPoint(x: 20, y: 15))
                    path.addLine(to: CGPoint(x: 40, y: 25))
                    path.addLine(to: CGPoint(x: 60, y: 0))
                    return path
                }()
            )),
        ]

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let views: [AccessibilityPathView]

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        for subview in views {
            subview.backgroundColor = .lightGray
            subview.isAccessibilityElement = true
            subview.accessibilityLabel = "Label"
            subview.frame.size = .init(width: 60, height: 40)
            view.addSubview(subview)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for subview in views {
            distributionSpecifiers.append(subview)
            distributionSpecifiers.append(1.flexible)
        }
        view.applySubviewDistribution(distributionSpecifiers)
    }

}

// MARK: -

private extension AccessibilityPathViewController {

    final class AccessibilityPathView: UIView {

        // MARK: - Life Cycle

        init(relativePath: UIBezierPath) {
            self.relativePath = relativePath

            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let relativePath: UIBezierPath

        // MARK: - UIAccessibility

        override var accessibilityPath: UIBezierPath? {
            get {
                return UIAccessibility.convertToScreenCoordinates(relativePath, in: self)
            }
            set {
                super.accessibilityPath = newValue
            }
        }

    }

}

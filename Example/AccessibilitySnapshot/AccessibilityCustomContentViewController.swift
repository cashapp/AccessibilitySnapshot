//
//  Copyright 2024 Block Inc.
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

import Accessibility
import Paralayout
import UIKit

@available(iOS 14.0, *)
final class AccessibilityCustomContentViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        view = View(
            views: [
                .init(includeLabel: true, includeHint: true),
                .init(includeLabel: true, includeHint: false),
                .init(includeLabel: false, includeHint: true),
                .init(includeLabel: false, includeHint: false),
            ]
        )
    }

}

// MARK: -
@available(iOS 14.0, *)
private extension AccessibilityCustomContentViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        init(views: [CustomContentView], frame: CGRect = .zero) {
            self.views = views

            super.init(frame: frame)

            views.forEach(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let views: [CustomContentView]

        // MARK: - UIView

        override func layoutSubviews() {
            views.forEach { $0.bounds.size = .init(width: bounds.width / 2, height: 50) }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
            for subview in views {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)
        }

    }

}

// MARK: -
@available(iOS 14.0, *)
private extension AccessibilityCustomContentViewController {
    
    final class CustomContentView: UIView, AXCustomContentProvider {
        // MARK: - Life Cycle

        init(includeLabel: Bool, includeHint: Bool) {
            super.init(frame: .zero)

            backgroundColor = .gray

            isAccessibilityElement = true

            accessibilityLabel = includeLabel ? "Label" : nil
            accessibilityHint = includeHint ? "Hint" : nil
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - UIAccessibility
        var accessibilityCustomContent: [AXCustomContent]! = {
            let customContent = AXCustomContent(label: "Custom Content Label", value: "Custom Content Value")

            let highImportance = AXCustomContent(label: "High Importance Label", value: "High Importance Value")
            highImportance.importance = .high
           
            return [customContent, highImportance]
        }()
    }
}

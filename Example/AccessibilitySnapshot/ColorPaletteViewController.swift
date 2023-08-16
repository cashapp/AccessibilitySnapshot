//
//  Copyright 2023 Block Inc.
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

final class ColorPaletteViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

}

// MARK: -

private extension ColorPaletteViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            let colors: [UIColor] = [
                .black,
                .blue,
                .brown,
                .cyan,
                .darkGray,
                .gray,
                .green,
                .lightGray,
                .magenta,
                .orange,
                .purple,
                .red,
                .white,
                .yellow,
                .systemRed,
                .systemBlue,
                .systemGray,
                .systemPink,
                .systemTeal,
                .systemBrown,
                .systemGreen,
                .systemIndigo,
                .systemOrange,
                .systemPurple,
                .systemYellow,
            ]

            colorViews = colors.map {
                let view = UIView()
                view.backgroundColor = $0
                return view
            }

            super.init(frame: frame)

            colorViews.forEach { addSubview($0) }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let colorViews: [UIView]

        // MARK: - UIView

        override func layoutSubviews() {
            verticallySpreadSubviews(colorViews, margin: 0)
        }

    }

}

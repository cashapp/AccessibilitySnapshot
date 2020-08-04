//
//  Copyright 2020 Square Inc.
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

import UIKit

final class ContainerView: UIView {

    // MARK: - Life Cycle

    init(subview: UIView) {
        self.subview = subview

        super.init(frame: .zero)

        backgroundColor = .white

        addSubview(subview)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let subview: UIView

    // MARK: - UIView

    override func layoutSubviews() {
        subview.frame.size = subview.sizeThatFits(bounds.insetBy(dx: 10, dy: 10).size)
        subview.alignToSuperview(.center)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let subviewSize = subview.sizeThatFits(size)
        return CGSize(width: size.width, height: subviewSize.height + 20)
    }

}

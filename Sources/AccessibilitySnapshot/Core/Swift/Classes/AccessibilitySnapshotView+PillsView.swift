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

import UIKit

extension AccessibilitySnapshotView {
    
    fileprivate enum Metrics {
        static let pillPadding = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        static let pillHorizontalMargin: CGFloat = 4
        static let pillVerticalMargin: CGFloat = 4
        static let pillCornerRadius: CGFloat = 6
        static let font: UIFont = .systemFont(ofSize: 12)
    }
    
    private final class PillView: UIView {
        private let label: UILabel = .init()
        
        init(
            title: String
        ) {
            super.init(frame: .zero)
            
            setUpView(title: title)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpView(title: String) {
            backgroundColor = .init(white: 0.8, alpha: 1.0)
            layer.cornerRadius = Metrics.pillCornerRadius
            clipsToBounds = true
            
            label.text = title
            label.numberOfLines = 1
            label.textAlignment = .center
            label.textColor = .init(white: 0.2, alpha: 1.0)
            label.lineBreakMode = .byTruncatingTail
            label.font = Metrics.font
            
            addSubview(label)
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let labelSize = label.sizeThatFits(size)
            let width: CGFloat = .minimum(size.width, labelSize.width + Metrics.pillPadding.left + Metrics.pillPadding.right)
            
            return .init(
                width: width,
                height: labelSize.height + Metrics.pillPadding.top + Metrics.pillPadding.bottom
            )
        }
        
        override func layoutSubviews() {
            label.frame = bounds.inset(by: Metrics.pillPadding)
        }
    }
    
    internal final class PillsView: UIView {
        private let pills: [PillView]
        
        init(titles: [String], color: UIColor) {
            pills = titles.map { PillView(title: $0) }
            
            super.init(frame: .zero)
            
            pills.forEach {
                addSubview($0)
            }
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var offset = CGPoint(x: 0.0, y: 0.0)
            
            pills.forEach {
                let sizeThatFits = $0.sizeThatFits(size)
                
                let willPillFitInCurrentLine = sizeThatFits.width <= size.width - offset.x
                
                if willPillFitInCurrentLine {
                    offset.x += sizeThatFits.width + Metrics.pillHorizontalMargin
                } else {
                    // if pill won't fit in current line, start a new line
                    offset.x = sizeThatFits.width + Metrics.pillHorizontalMargin
                    offset.y += sizeThatFits.height + Metrics.pillVerticalMargin
                }
            }
            
            return .init(
                width: size.width,
                height: offset.y +  (pills.last?.sizeThatFits(size).height ?? .zero)
            )
        }
        
        override func layoutSubviews() {
            var offset = CGPoint(x: 0.0, y: 0.0)
            
            pills.forEach {
                let pillSize = $0.sizeThatFits(bounds.size)
                let currentPillWidth = pillSize.width
                let currentPillHeight = pillSize.height
                
                let willPillFitInCurrentLine = currentPillWidth <= bounds.size.width - offset.x
                
                if willPillFitInCurrentLine {
                    $0.frame.origin = CGPoint(x: offset.x, y: offset.y)
                    offset.x += pillSize.width + Metrics.pillHorizontalMargin
                } else {
                    // if pill won't fit in current line, start a new line
                    offset.y += currentPillHeight + Metrics.pillVerticalMargin
                    $0.frame.origin = CGPoint(x: 0.0, y: offset.y)
                    offset.x = pillSize.width + Metrics.pillHorizontalMargin
                }
                
                $0.frame.size = pillSize
            }
        }
    }
    
}

//
//  Copyright 2023 Square Inc.
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

internal extension AccessibilitySnapshotView {
    
    fileprivate enum Metrics {
        static let verticalSpacing: CGFloat = 4
        static let pillHorizontalPadding: CGFloat = 4
        static let pillVerticalPadding: CGFloat = 2
        static let pillHorizontalMargin: CGFloat = 4
        static let pillVerticalMargin: CGFloat = 4
        static let pillCornerRadius: CGFloat = 6
        static let pillBorderWidth: CGFloat = 2
        static let font: UIFont = .systemFont(ofSize: 12)
    }
    
    private class PillView: UIView {
        private let label: UILabel = .init()
        
        init(
            title: String,
            color: UIColor
        ) {
            super.init(frame: .zero)
            
            setUpView(title: title, color: color)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpView(title: String, color: UIColor) {
            layer.cornerRadius = Metrics.pillCornerRadius
            layer.borderWidth = Metrics.pillBorderWidth
            layer.borderColor = color.cgColor
            clipsToBounds = true
            
            label.text = title
            label.numberOfLines = 1
            label.textAlignment = .center
            label.textColor = .init(white: 0.3, alpha: 1.0)
            label.lineBreakMode = .byTruncatingTail
            label.font = Metrics.font
            
            addSubview(label)
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let labelSize = label.sizeThatFits(size)
            let width: CGFloat = .minimum(size.width, labelSize.width + Metrics.pillHorizontalPadding * 2)
            
            return .init(
                width: width,
                height: labelSize.height + Metrics.pillVerticalPadding * 2
            )
        }
        
        override func layoutSubviews() {
            label.frame = CGRect(
                x: bounds.minX + Metrics.pillHorizontalPadding,
                y: bounds.minY + Metrics.pillVerticalPadding,
                width: bounds.maxX - 2 * Metrics.pillHorizontalPadding,
                height: bounds.maxY - 2 * Metrics.pillVerticalPadding
            )
        }
    }
    
    class PillsView: UIView {
        private let pills: [PillView]
        
        init(titles: [String], color: UIColor) {
            pills = titles.map { PillView(title: $0, color: color) }
            
            super.init(frame: .zero)
            
            pills.forEach {
                $0.sizeToFit()
                addSubview($0)
            }
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var offset: (CGFloat, CGFloat) = (0.0, 0.0) // (offsetX, offsetY)
            
            pills.forEach {
                let sizeThatFits = $0.sizeThatFits(size)
                
                let willPillFitInCurrentLine = sizeThatFits.width <= size.width - offset.0
                
                if willPillFitInCurrentLine {
                    offset.0 += sizeThatFits.width + Metrics.pillHorizontalMargin
                } else {
                    // if pill won't fit in current line, start a new line
                    offset.0 = sizeThatFits.width + Metrics.pillHorizontalMargin
                    offset.1 += sizeThatFits.height + Metrics.pillVerticalMargin
                }
            }
            
            return .init(
                width: size.width,
                height: offset.1 + (pills.last?.bounds.size.height ?? .zero)
            )
        }
        
        override func layoutSubviews() {
            var offset: (CGFloat, CGFloat) = (0.0, 0.0) // (offsetX, offsetY)
            
            pills.forEach {
                let pillSize = $0.sizeThatFits(bounds.size)
                let currentPillWidth = pillSize.width
                let currentPillHeight = pillSize.height
                
                let willPillFitInCurrentLine = currentPillWidth <= bounds.size.width - offset.0
                
                if willPillFitInCurrentLine {
                    $0.frame.origin = CGPoint(x: offset.0, y: offset.1)
                    offset.0 += $0.frame.maxX + Metrics.pillHorizontalMargin
                } else {
                    // if pill won't fit in current line, start a new line
                    offset.1 += currentPillHeight + Metrics.pillVerticalMargin
                    $0.frame.origin = CGPoint(x: 0.0, y: offset.1)
                    offset.0 = $0.frame.maxX + Metrics.pillHorizontalMargin
                }
                
                $0.frame.size = pillSize
            }
        }
    }
    
}

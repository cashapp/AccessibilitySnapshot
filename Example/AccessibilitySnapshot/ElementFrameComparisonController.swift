//
//  Copyright 2025 Square Inc.
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

class ElementFrameComparisonController: AccessibilityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let header = MyLabel("Header")
        header.accessibilityTraits = [.staticText, .header]
        let label = MyLabel("Paragraph")
        let spacing  = 20.0
        
        // 8 seems to be the magic number for VoiceOver to consider it
        // to be vertically "above" other views
        let voiceoverMagicNumber = 8.0

        let frames = UIStackView(arrangedSubviews: [
            // Label where the accessibilityFrame will be the view's frame
            // translated vertically by 8 pt down
            MyLabel(
                "frame down",
                accessibilityLabel: "Third",
                accessibilityFrame: .rect({
                    var rect = $0
                    rect.origin.y += voiceoverMagicNumber
                    return rect
                })
            ),
            
            // Label where the accessibilityFrame is unmodified
            MyLabel( "unchanged", accessibilityLabel: "Second"),
            
            // Label where the accessibilityFrame will be the view's frame
            // translated vertically by 8 pt up
            MyLabel(
                "frame up",
                accessibilityLabel: "First",
                accessibilityFrame: .rect({
                    var rect = $0
                    rect.origin.y -= voiceoverMagicNumber
                    return rect
                })
            )
        ])
        
        let paths = UIStackView(arrangedSubviews: [
            
            // Label where the accessibilityPath will be the view's frame
            // translated vertically by 8 pt down
            MyLabel(
                "path down",
                accessibilityLabel: "Fourth",
                accessibilityFrame: .path({
                    var rect = $0
                    rect.origin.y += voiceoverMagicNumber
                    return UIBezierPath(roundedRect: rect, cornerRadius: 5)
                })
            ),
            
            // Label where the accessibilityPath is unmodified
            MyLabel(
                "path unchanged",
                accessibilityLabel: "Fifth",
                accessibilityFrame: .path({
                         return UIBezierPath(roundedRect: $0, cornerRadius: 5)
                     })
                ),

            
            // Label where the accessibilityPath will be the view's frame
            // translated vertically by 8 pt up
            MyLabel(
                "path up",
                accessibilityLabel: "Sixth",
                accessibilityFrame: .path({
                    var rect = $0
                    rect.origin.y -= voiceoverMagicNumber
                    return UIBezierPath(roundedRect: rect, cornerRadius: 5)
                })
            )
   
        ])

        frames.axis = .horizontal
        paths.axis = .horizontal
        
        frames.spacing = spacing
        paths.spacing = spacing

        view.addSubview(header)
        view.addSubview(frames)
        view.addSubview(paths)

        view.addSubview(label)

        header.translatesAutoresizingMaskIntoConstraints = false
        frames.translatesAutoresizingMaskIntoConstraints = false
        paths.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: spacing),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            frames.topAnchor.constraint(equalTo: header.bottomAnchor, constant: spacing),
            frames.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frames.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            paths.topAnchor.constraint(equalTo: frames.bottomAnchor, constant: spacing),
            paths.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paths.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            label.topAnchor.constraint(equalTo: paths.bottomAnchor, constant: spacing),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}

enum AccessibilityFrame {
    case `default`
    case path((CGRect) -> UIBezierPath)
    case rect((CGRect) -> CGRect)
}

class MyLabel: UILabel {

    private let _accessibilityFrame: AccessibilityFrame

    init(_ text: String, align: NSTextAlignment = .left, accessibilityLabel: String? = nil, accessibilityFrame: AccessibilityFrame = .default) {
        self._accessibilityFrame = accessibilityFrame
        super.init(frame: .zero)
        self.text = text
        self.textAlignment = align
        self.backgroundColor = .gray.withAlphaComponent(0.2)
        if let accessibilityLabel {
            self.accessibilityLabel = accessibilityLabel
        }
    }

    required init?(coder: NSCoder) { nil }

    override var accessibilityPath: UIBezierPath? {
        set { _ = newValue }
        get {
            switch _accessibilityFrame {

            case .default, .rect:
                return nil

            case .path(let transform):
                guard let superview else { return nil }
                return UIAccessibility.convertToScreenCoordinates(transform(frame), in: superview)
            }
        }
    }

    override var accessibilityFrame: CGRect {
        set { _ = newValue }
        get {
            switch _accessibilityFrame {
            case .default, .path:
                return super.accessibilityFrame

            case .rect(let transform):
                guard let superview else { return super.accessibilityFrame }
                return UIAccessibility.convertToScreenCoordinates(transform(frame), in: superview)
            }
        }
    }
}

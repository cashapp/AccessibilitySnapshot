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

@testable import SnapshotTesting
import UIKit

// MARK: - UIImage

public extension Snapshotting where Value == UIImage, Format == UIImage {
    static func accessibilityImage(
        simulateColorBlindness type: MatrixTypes
    ) -> Snapshotting {
        return Snapshotting<UIImage, UIImage>.image.pullback { image in
            image.applyFilterMatrix(type)!
        }
    }
}

// MARK: - UIViewController

public extension Snapshotting where Value == UIViewController, Format == UIImage {
    static func accessibilityImage(
        simulateColorBlindness type: MatrixTypes,
        on config: ViewImageConfig,
        precision: Float = 1,
        size: CGSize? = nil,
        traits: UITraitCollection = .init()
    ) -> Snapshotting {
        return SimplySnapshotting.image(precision: precision).asyncPullback { viewController in
            snapshotView(
                config: size.map { .init(safeArea: config.safeArea, size: $0, traits: config.traits) } ?? config,
                drawHierarchyInKeyWindow: false,
                traits: traits,
                view: viewController.view,
                viewController: viewController
            ).map {
                $0.applyFilterMatrix(type)!
            }
        }
    }
}

// MARK: - UIView

public extension Snapshotting where Value == UIView, Format == UIImage {
    static func accessibilityImage(
        simulateColorBlindness type: MatrixTypes,
        on config: ViewImageConfig,
        precision: Float = 1,
        size: CGSize? = nil,
        traits: UITraitCollection = .init()
    ) -> Snapshotting {
        return SimplySnapshotting.image(precision: precision).asyncPullback { view in
            snapshotView(
                config: size.map { .init(safeArea: config.safeArea, size: $0, traits: config.traits) } ?? config,
                drawHierarchyInKeyWindow: false,
                traits: traits,
                view: view,
                viewController: .init()
            ).map {
                $0.applyFilterMatrix(type)!
            }
        }
    }
}

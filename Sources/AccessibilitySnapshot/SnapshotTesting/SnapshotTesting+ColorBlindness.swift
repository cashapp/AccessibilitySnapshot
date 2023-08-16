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

@testable import SnapshotTesting

// MARK: - UIImage

extension Snapshotting where Value == UIImage, Format == UIImage {

    public static func image(
        simulateColorBlindness type: ColorBlindnessType
    ) -> Snapshotting {
        return Snapshotting<UIImage, UIImage>.image.pullback { image in
            image.applyColorBlindFilter(type)
        }
    }

}

// MARK: - UIViewController

extension Snapshotting where Value == UIViewController, Format == UIImage {

    public static func image(
        simulateColorBlindness type: ColorBlindnessType,
        drawHierarchyInKeyWindow: Bool = false,
        on config: ViewImageConfig? = nil
    ) -> Snapshotting {
        return SimplySnapshotting.image.asyncPullback { viewController in
            snapshotView(
                config: config ?? .init(size: viewController.view.bounds.size),
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                traits: config?.traits ?? .init(),
                view: viewController.view,
                viewController: viewController
            ).map {
                $0.applyColorBlindFilter(type)
            }
        }
    }

}

// MARK: - UIView

extension Snapshotting where Value == UIView, Format == UIImage {

    public static func image(
        simulateColorBlindness type: ColorBlindnessType,
        drawHierarchyInKeyWindow: Bool = false,
        on config: ViewImageConfig? = nil
    ) -> Snapshotting {
        return SimplySnapshotting.image.asyncPullback { view in
            snapshotView(
                config: config ?? .init(size: view.bounds.size),
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                traits: config?.traits ?? .init(),
                view: view,
                viewController: .init()
            ).map {
                $0.applyColorBlindFilter(type)
            }
        }
    }

}

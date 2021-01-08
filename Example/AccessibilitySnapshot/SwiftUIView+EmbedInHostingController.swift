//
//  Copyright 2021 Square Inc.
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
import SwiftUI

@available(iOS 13.0, *)
extension View {

    // should be removed again when AccessibilitySnapshot supports snapshotting
    // native SwiftUI views, see AccessibilitySnapshot/issues/37
    func toVC() -> UIViewController {
        let viewController = UIViewController()

        let hostingController = UIHostingController(rootView: self)
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            hostingController.view.leftAnchor.constraint(equalTo: viewController.view.leftAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor),
            viewController.view.rightAnchor.constraint(equalTo: hostingController.view.rightAnchor)
        ])

        hostingController.didMove(toParent: viewController)

        return viewController
    }
}

//
//  SwiftUIView+EmbedInHostingController.swift
//  AccessibilitySnapshotDemo
//
//  Created by Felizia Bernutz on 15.10.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import SwiftUI

@available(iOS 13.0, *)
extension View {

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

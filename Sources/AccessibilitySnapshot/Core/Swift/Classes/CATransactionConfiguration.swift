//
//  Copyright 2019 Square Inc.
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

import Foundation

/// A configuration for the `CATransaction` utilized during layout of the snapshotted content.
public struct CATransactionConfiguration {

    /// Corresponds to the `CATransaction.animationDuration()` value. If no value is provided, a value will not be set
    /// on the `CATransaction`.
    public var animationDuration: CFTimeInterval?

    /// Corresponds to the `CATransaction.disableActions()` value. If no value is provided, a value will not be set on
    /// the `CATransaction`.
    public var actionsDisabled: Bool?

    /// Creates configuration for the `CATransaction` utilized during layout of the snapshotted content.
    ///
    /// - parameter animationDuration: Corresponds to the `CATransaction.animationDuration()` value. If no value is
    /// provided, a value will not be set on the `CATransaction`.
    /// - parameter actionsDisabled: Corresponds to the `CATransaction.disableActions()` value. If no value is provided,
    /// a value will not be set on the `CATransaction`.
    public init(
        animationDuration: CFTimeInterval? = nil,
        actionsDisabled: Bool? = nil
    ) {
        self.animationDuration = animationDuration
        self.actionsDisabled = actionsDisabled
    }

    /// Disables animations during the `CATransaction`.
    ///
    /// This uses an `animationDuration` of `0` and disabled actions.
    public static var disableAnimations: Self {
        .init(animationDuration: 0, actionsDisabled: true)
    }
}

extension CATransaction {

    /// Performs the operation in a `CATransaction` if a non-nil `configuration` is provided.
    ///
    /// If a `nil` `configuration` is provided, the action will be performed without a `CATransaction`.
    public func perform(
        configuration: CATransactionConfiguration?,
        action: () -> Void
    ) {
        guard let configuration = configuration else {
            action()
            return
        }

        CATransaction.begin()

        if let animatioDuration = configuration.animationDuration {
            CATransaction.setAnimationDuration(animationDuration)
        }

        if let actionsDisabled = configuration.actionsDisabled {
            CATransaction.setDisableActions(actionsDisabled)
        }

        action()

        CATransaction.commit()
    }

}

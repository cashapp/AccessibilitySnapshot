//
//  Copyright 2024 Block Inc.
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

#if SWIFT_PACKAGE || BAZEL_PACKAGE
import AccessibilitySnapshotCore
import AccessibilitySnapshotCore_ObjC
import iOSSnapshotTestCase
#else
import FBSnapshotTestCase
#endif

extension FBSnapshotTestCase {

    @objc(snapshotVerifyAccessibility:identifier:perPixelTolerance:overallTolerance:)
    private func 🚫objc_snapshotVerifyAccessibility(
        _ view: UIView,
        identifier: String,
        perPixelTolerance: CGFloat,
        overallTolerance: CGFloat
    ) -> String? {
        return snapshotVerifyAccessibility(
            view,
            identifier: identifier,
            activationPointDisplayMode: .whenOverridden,
            useMonochromeSnapshot: true,
            perPixelTolerance: perPixelTolerance,
            overallTolerance: overallTolerance,
            showUserInputLabels: true
        )
    }

    @objc(snapshotVerifyAccessibility:identifier:showActivationPoints:useMonochromeSnapshot:perPixelTolerance:overallTolerance:showUserInputLabels:)
    private func 🚫objc_snapshotVerifyAccessibility(
        _ view: UIView,
        identifier: String,
        showActivationPoints: Bool,
        useMonochromeSnapshot: Bool,
        perPixelTolerance: CGFloat,
        overallTolerance: CGFloat,
        showUserInputLabels: Bool
    ) -> String? {
        return snapshotVerifyAccessibility(
            view,
            identifier: identifier,
            activationPointDisplayMode: showActivationPoints ? .always : .never,
            useMonochromeSnapshot: useMonochromeSnapshot,
            perPixelTolerance: perPixelTolerance,
            overallTolerance: overallTolerance,
            showUserInputLabels: showUserInputLabels
        )
    }

    @nonobjc
    internal func snapshotVerifyAccessibility(
        _ view: UIView,
        identifier: String,
        activationPointDisplayMode: ActivationPointDisplayMode,
        useMonochromeSnapshot: Bool,
        perPixelTolerance: CGFloat,
        overallTolerance: CGFloat,
        showUserInputLabels: Bool
    ) -> String? {
        guard isRunningInHostApplication else {
            return ErrorMessageFactory.errorMessageForMissingHostApplication
        }

        let containerView = AccessibilitySnapshotView(
            containedView: view,
            viewRenderingMode: (usesDrawViewHierarchyInRect ? .drawHierarchyInRect : .renderLayerInContext),
            activationPointDisplayMode: activationPointDisplayMode,
            showUserInputLabels: showUserInputLabels
        )

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        containerView.center = window.center
        window.addSubview(containerView)

        do {
            try containerView.parseAccessibility(useMonochromeSnapshot: useMonochromeSnapshot)
        } catch {
            return ErrorMessageFactory.errorMessageForAccessibilityParsingError(error)
        }

        containerView.sizeToFit()

        return snapshotVerifyViewOrLayer(
            containerView,
            identifier: identifier,
            suffixes: FBSnapshotTestCaseDefaultSuffixes(),
            perPixelTolerance: perPixelTolerance,
            overallTolerance: overallTolerance,
            defaultReferenceDirectory: FB_REFERENCE_IMAGE_DIR,
            defaultImageDiffDirectory: IMAGE_DIFF_DIR
        )
    }

    @objc(snapshotVerifyWithInvertedColors:identifier:perPixelTolerance:overallTolerance:)
    private func snapshotVerifyWithInvertedColors(
        _ view: UIView,
        identifier: String,
        perPixelTolerance: CGFloat,
        overallTolerance: CGFloat
    ) -> String? {
        func postNotification() {
            NotificationCenter.default.post(
                name: UIAccessibility.invertColorsStatusDidChangeNotification,
                object: nil,
                userInfo: nil
            )
        }

        let requiresWindow = (view.window == nil && !(view is UIWindow))
        if requiresWindow {
            let window = UIApplication.shared.firstKeyWindow ?? UIWindow(frame: UIScreen.main.bounds)
            window.addSubview(view)
        }

        view.layoutIfNeeded()

        let statusUtility = UIAccessibilityStatusUtility()
        statusUtility.mockInvertColorsStatus()
        postNotification()

        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { context in
            view.drawHierarchyWithInvertedColors(in: view.bounds, using: context)
        }

        let imageView = UIImageView(image: image)
        let errorDescription = snapshotVerifyViewOrLayer(
            imageView,
            identifier: identifier,
            suffixes: FBSnapshotTestCaseDefaultSuffixes(),
            perPixelTolerance: perPixelTolerance,
            overallTolerance: overallTolerance,
            defaultReferenceDirectory: FB_REFERENCE_IMAGE_DIR,
            defaultImageDiffDirectory: IMAGE_DIFF_DIR
        )

        statusUtility.unmockStatuses()
        postNotification()

        if requiresWindow {
            view.removeFromSuperview()
        }

        return errorDescription
    }

    @objc(snapshotVerifyWithHitTargets:identifier:useMonochromeSnapshot:maxPermissibleMissedRegionWidth:maxPermissibleMissedRegionHeight:perPixelTolerance:overallTolerance:)
    private func snapshotVerifyWithHitTargets(
        _ view: UIView,
        identifier: String,
        useMonochromeSnapshot: Bool,
        maxPermissibleMissedRegionWidth: CGFloat,
        maxPermissibleMissedRegionHeight: CGFloat,
        perPixelTolerance: CGFloat,
        overallTolerance: CGFloat
    ) -> String? {
        do {
            let containerView = try HitTargetSnapshotView(
                baseView: view,
                useMonochromeSnapshot: useMonochromeSnapshot,
                viewRenderingMode: (usesDrawViewHierarchyInRect ? .drawHierarchyInRect : .renderLayerInContext),
                colors: AccessibilitySnapshotView.defaultMarkerColors,
                maxPermissibleMissedRegionWidth: maxPermissibleMissedRegionWidth,
                maxPermissibleMissedRegionHeight: maxPermissibleMissedRegionHeight
            )

            containerView.sizeToFit()

            return snapshotVerifyViewOrLayer(
                containerView,
                identifier: identifier,
                suffixes: FBSnapshotTestCaseDefaultSuffixes(),
                perPixelTolerance: perPixelTolerance,
                overallTolerance: overallTolerance,
                defaultReferenceDirectory: FB_REFERENCE_IMAGE_DIR,
                defaultImageDiffDirectory: IMAGE_DIFF_DIR
            )

        } catch {
            return ErrorMessageFactory.errorMessageForAccessibilityParsingError(error)
        }
    }

}

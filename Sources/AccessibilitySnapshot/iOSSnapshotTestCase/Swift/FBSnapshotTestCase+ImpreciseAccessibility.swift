import AccessibilitySnapshotCore
import AccessibilitySnapshotParser_ObjC
import iOSSnapshotTestCase
import XCTest

public extension FBSnapshotTestCase {
    /// Snapshots the `view` with colored overlays of each accessibility element it contains, as well as an
    /// approximation of the description that VoiceOver will read for each element.
    ///
    /// - Warning: Using a `perPixelTolerance` or `overallTolerance` greater than `0` may result in allowing regressions
    /// through. Prefer using `perPixelTolerance` over `overallTolerance` where possible, and only raise the tolerances
    /// to the extent needed to allow your tests to pass across multiple machines.
    @available(*, deprecated, message: "Use SnapshotVerifyAccessibility with perPixelTolerance and overallTolerance parameters instead.")
    func SnapshotImpreciseVerifyAccessibility(
        _ view: UIView,
        identifier: String = "",
        showActivationPoints activationPointDisplayMode: AccessibilityContentDisplayMode = .whenOverridden,
        useMonochromeSnapshot: Bool = true,
        markerColors: [UIColor] = [],
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        perPixelTolerance: CGFloat = 0,
        overallTolerance: CGFloat = 0,
        showUserInputLabels: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let configuration = AccessibilitySnapshotConfiguration(
            viewRenderingMode: viewRenderingMode,
            colorRenderingMode: useMonochromeSnapshot ? .monochrome : .fullColor,
            overlayColors: markerColors,
            activationPointDisplay: activationPointDisplayMode,
            includesInputLabels: showUserInputLabels ? .whenOverridden : .never
        )

        SnapshotVerifyAccessibility(
            view,
            identifier: identifier,
            snapshotConfiguration: configuration,
            suffixes: suffixes,
            perPixelTolerance: perPixelTolerance,
            overallTolerance: overallTolerance,
            file: file,
            line: line
        )
    }

    /// Snapshots the `view` simulating the way it will appear with Smart Invert Colors enabled.
    ///
    /// - Warning: Using a `perPixelTolerance` or `overallTolerance` greater than `0` may result in allowing regressions
    /// through. Prefer using `perPixelTolerance` over `overallTolerance` where possible, and only raise the tolerances
    /// to the extent needed to allow your tests to pass across multiple machines.
    @available(*, deprecated, message: "Use SnapshotVerifyWithInvertedColors with perPixelTolerance and overallTolerance parameters instead.")
    func SnapshotImpreciseVerifyWithInvertedColors(
        _ view: UIView,
        identifier: String = "",
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        perPixelTolerance: CGFloat = 0,
        overallTolerance: CGFloat = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        SnapshotVerifyWithInvertedColors(
            view,
            identifier: identifier,
            suffixes: suffixes,
            perPixelTolerance: perPixelTolerance,
            overallTolerance: overallTolerance,
            file: file,
            line: line
        )
    }

    /// Snapshots the `view` with hit target regions highlighted.
    ///
    /// - Warning: Using a `perPixelTolerance` or `overallTolerance` greater than `0` may result in allowing regressions
    /// through. Prefer using `perPixelTolerance` over `overallTolerance` where possible, and only raise the tolerances
    /// to the extent needed to allow your tests to pass across multiple machines.
    @available(*, deprecated, message: "Use SnapshotVerifyWithHitTargets with perPixelTolerance and overallTolerance parameters instead.")
    func SnapshotImpreciseVerifyWithHitTargets(
        _ view: UIView,
        identifier: String = "",
        useMonochromeSnapshot: Bool = true,
        colors: [UIColor] = MarkerColors.defaultColors,
        maxPermissibleMissedRegionWidth: CGFloat = 0,
        maxPermissibleMissedRegionHeight: CGFloat = 0,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        perPixelTolerance: CGFloat = 0,
        overallTolerance: CGFloat = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        SnapshotVerifyWithHitTargets(
            view,
            identifier: identifier,
            useMonochromeSnapshot: useMonochromeSnapshot,
            colors: colors,
            maxPermissibleMissedRegionWidth: maxPermissibleMissedRegionWidth,
            maxPermissibleMissedRegionHeight: maxPermissibleMissedRegionHeight,
            suffixes: suffixes,
            perPixelTolerance: perPixelTolerance,
            overallTolerance: overallTolerance,
            file: file,
            line: line
        )
    }
}

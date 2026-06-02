---
date: 2026-04-07T10:33:21Z
researcher: Claude
git_commit: 5a9399fc
branch: a11y-container-graph
repository: AccessibilitySnapshot
topic: "Snapshot layout architecture: how legends, overlays, and the snapshot image interact"
tags: [research, codebase, snapshot-layout, legend, overlay, swiftui, uikit]
status: complete
last_updated: 2026-04-07
last_updated_by: Claude
---

# Research: Snapshot Layout Architecture

**Date**: 2026-04-07T10:33:21Z
**Git Commit**: 5a9399fc
**Branch**: a11y-container-graph
**Repository**: AccessibilitySnapshot

## Research Question

How are snapshots built? What causes the legend to be on one side or another? Can the legend grow arbitrarily without affecting the overlay/snapshot view? Do element overlays share the coordinate space with the snapshot image via SwiftUI's `.overlay()` modifier?

## Summary

The system has two rendering paths (UIKit and SwiftUI) with different layout engines but the same structural pattern: a snapshot image, element overlays in the image's coordinate space, and a legend placed either to the right or below. Both paths use the snapshot's aspect ratio and minimum width threshold to decide legend placement. The element overlays DO share the snapshot image's coordinate space — in SwiftUI via `.overlay()`, in UIKit via `snapshotView.addSubview()`. The legend is a separate sibling view and CAN grow arbitrarily without affecting the overlay/snapshot — but only if the outer layout doesn't apply `.frame(width:)` to the snapshot portion (which the VStack path currently does).

## Detailed Findings

### 1. Two Rendering Paths

#### UIKit Path (`AccessibilitySnapshotView`)
- **Class chain**: `UIView > SnapshotAndLegendView > AccessibilitySnapshotBaseView > AccessibilitySnapshotView`
- `SnapshotAndLegendView` owns a `UIImageView` called `snapshotView` (`SnapshotAndLegendView.swift:20`)
- Overlay views are added as **subviews of `snapshotView`** (`AccessibilitySnapshotView.swift:103`), sharing its coordinate space exactly
- Legend views are added as **subviews of `self`** (the outer container), positioned by `layoutSubviews()`

#### SwiftUI Path (`PreParsedAccessibilitySnapshotView`)
- **Bridge**: `SwiftUIAccessibilitySnapshotContainerView` overrides `render(data:)` to create a `UIHostingController` wrapping `PreParsedAccessibilitySnapshotView`
- The parent class's `snapshotView` is hidden (`SwiftUIAccessibilitySnapshotContainerView.swift:62`)
- All layout decisions happen inside the SwiftUI view's `body`
- `sizeThatFits`, `layoutSubviews`, and `intrinsicContentSize` all delegate to the hosting controller

### 2. Legend Placement Decision

Both paths use the same logic (aspect ratio + minimum width):

**UIKit** (`SnapshotAndLegendView.swift:186-201`):
- `aspectRatio > 1` (wider than tall) OR `viewSize.width < minimumWidth` → legend below (`.bottom`)
- Otherwise → legend right (`.right`)

**SwiftUI** (`SwiftUIAccessibilitySnapshotView.swift:237-241`):
```swift
private var legendOnRight: Bool {
    let aspectRatio = renderSize.width / renderSize.height
    let minimumWidth = LegendLayoutMetrics.minimumWidth
    return aspectRatio <= 1 && renderSize.width >= minimumWidth
}
```

The threshold is `minimumWidth = 316pt` (284pt legend column + 2 x 16pt inset).

### 3. Element Overlays Share Coordinate Space with Snapshot

#### SwiftUI: Yes, via `.overlay()`

`SwiftUIAccessibilitySnapshotView.swift:306-310`:
```swift
Image(uiImage: snapshotImage)
    .resizable()
    .frame(width: renderSize.width, height: renderSize.height)
    .overlay(preParsedElementOverlayLayer)
    .clipped()
```

The `.overlay()` modifier sizes the overlay to match the Image. The overlay is a `ZStack(alignment: .topLeading)` also explicitly constrained to `renderSize.width x renderSize.height` (`SwiftUIAccessibilitySnapshotView.swift:330`).

Each `ElementOverlay` uses `.position(x: rect.midX, y: rect.midY)` (`ElementView.swift:95, 108`) — absolute coordinates in the parent ZStack, which maps 1:1 to the snapshot image pixels.

#### UIKit: Yes, via `snapshotView.addSubview()`

`AccessibilitySnapshotView.swift:95-103`:
```swift
let overlayView = OverlayView(frame: snapshotView.bounds, ...)
snapshotView.addSubview(overlayView)
```

Overlays are direct subviews of the `UIImageView`, so their coordinate origin is the image's top-left pixel.

### 4. How the Legend Is Rendered

Two legend strategies:

#### Flat Legend (`LegendView` / `multiColumnLegend`)
- `LegendView` (`SwiftUILegendView.swift:7-40`): single-column VStack of `LegendEntryView` items, with `.frame(maxWidth: .infinity)` — fills whatever width offered
- `multiColumnLegend` (`SwiftUIAccessibilitySnapshotView.swift:282-302`): wraps entries in `ColumnWrapLayout` with `availableHeight = renderSize.height - 32`, `columnWidth = 284pt`. Wraps to a new column when height would exceed `availableHeight`

#### Hierarchy Legend (`HierarchyLegendView`)
- `HierarchyLegendView.swift:7-50`: recursive `VStack` walking `AssignedNode` tree
- Elements → `LegendEntryView`; Containers → `ContainerLegendEntryView` (dashed border box with badge on top edge, children inside)
- Uses `.frame(maxWidth: .infinity)` — flexible width

### 5. Snapshot Positioning in Each Layout

#### UIKit: `.right` → origin (0,0); `.bottom` → centered horizontally

`SnapshotAndLegendView.layoutSubviews()`:
- `.right` case (line 72): `snapshotView.frame.origin = .zero` — always top-left
- `.bottom` case (line 60): `snapshotView.frame.origin.x = ((bounds.width - snapshotView.frame.width) / 2).floorToPixel(in: window)` — centered

#### SwiftUI: HStack → no outer frame; VStack → `.frame(width: contentWidth)`

`PreParsedAccessibilitySnapshotView.body`:
- `legendOnRight` (HStack, line 250-253): `snapshotWithOverlays` placed as-is, no `.frame(width:)` wrapper
- else (VStack, line 256-263): `snapshotWithOverlays.frame(width: contentWidth)` where `contentWidth = max(renderSize.width, 316)`

When `contentWidth > renderSize.width`, SwiftUI centers the snapshot inside the wider frame, shifting overlays.

For typical iPhone screens (402pt width), `contentWidth == renderSize.width`, so no centering occurs. The snapshot position is identical in both layout paths.

### 6. Capture Flow

`FBSnapshotTestCase+Accessibility.swift:169-191`:
1. `UIWindow` created at `UIScreen.main.bounds`
2. `containerView` added as subview
3. `containerView.parseAccessibility()` — renders image, parses hierarchy, calls `render(data:)`
4. `containerView.sizeToFit()` — queries `hostingController.sizeThatFits(in:)`
5. `FBSnapshotVerifyView(containerView)` — captures `containerView.bounds`

The hosting controller is sized with `width = data.containedViewBounds.width`, `height = UIView.layoutFittingExpandedSize.height` — width-constrained, height-unconstrained (`SwiftUIAccessibilitySnapshotContainerView.swift:54-57`).

## Code References

- `Sources/AccessibilitySnapshot/Core/SnapshotAndLegendView.swift:186-201` — `legendLocation(viewSize:)` decision
- `Sources/AccessibilitySnapshot/Core/SnapshotAndLegendView.swift:57-103` — `layoutSubviews()` positioning
- `Sources/AccessibilitySnapshot/Core/SnapshotAndLegendView.swift:105-182` — `sizeThatFits(_:)` computation
- `Sources/AccessibilitySnapshot/Core/AccessibilitySnapshotView.swift:95-103` — UIKit overlay added as subview of snapshotView
- `Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/SwiftUIAccessibilitySnapshotView.swift:237-241` — `legendOnRight` decision
- `Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/SwiftUIAccessibilitySnapshotView.swift:250-265` — HStack vs VStack body
- `Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/SwiftUIAccessibilitySnapshotView.swift:306-310` — `.overlay()` usage
- `Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/ElementView.swift:87-108` — `.position()` for absolute coordinates
- `Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/SwiftUIAccessibilitySnapshotContainerView.swift:33-66` — `render(data:)` bridge
- `Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/SwiftUIAccessibilitySnapshotContainerView.swift:54-57` — width-constrained sizing
- `Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/HierarchyLegendView.swift:7-50` — recursive tree rendering
- `Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/ColumnWrapLayout.swift:54-74` — column wrapping algorithm
- `Sources/AccessibilitySnapshot/Core/LegendLayoutMetrics.swift` — all layout constants

## Architecture Documentation

### Layout Constants (LegendLayoutMetrics)
| Constant | Value | Purpose |
|---|---|---|
| `legendInset` | 16pt | Padding inside legend container |
| `legendHorizontalSpacing` | 16pt | Space between legend columns |
| `legendVerticalSpacing` | 16pt | Space between legend items |
| `minimumLegendWidth` | 284pt | Width of each legend column |
| `minimumWidth` | 316pt | Threshold for right-side legend (284 + 2x16) |

### Coordinate Space Architecture
- **Snapshot image**: rendered at `CGRect(origin: .zero, size: renderSize)` via `UIHostingController`
- **Element overlays**: share the image's coordinate space via `.overlay()` (SwiftUI) or `snapshotView.addSubview()` (UIKit)
- **Legend**: separate sibling view, positioned by the layout engine (HStack/VStack in SwiftUI, `layoutSubviews()` in UIKit)
- **Marker coordinates**: parsed from the same `UIHostingController` frame, so they map 1:1 to image pixels

## Open Questions

- When `legendOnRight` is true and the hierarchy legend is selected, the legend appears in a narrow column beside a tall snapshot. The hierarchy legend (with nested container borders) may need more horizontal space than a flat legend column. Currently `legendOnRight` does not account for this.

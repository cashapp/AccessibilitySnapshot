---
date: 2026-04-07T10:00:00-07:00
researcher: claude
git_commit: 5a9399fcef23c698fabc03a36ad607ac80d03e59
branch: a11y-container-graph
repository: AccessibilitySnapshot
topic: "Container rendering implementation - current state vs design reference"
tags: [research, codebase, containers, rendering, overlays, legend, hierarchy]
status: complete
last_updated: 2026-04-07
last_updated_by: claude
---

# Research: Container Rendering Implementation

**Date**: 2026-04-07
**Branch**: a11y-container-graph
**Commit**: 5a9399fc

## Research Question
What is the current state of the container implementation in the view rendering, and how does it compare to the design reference (image-v9)?

## Design Reference (image-v9)

The design reference (saved to `.context/design-reference-containers-v9.png`) shows:

1. **Snapshot area (top)**: The original UI screenshot rendered with colored overlay rectangles on each accessibility element, each with a numbered badge in the top-left corner
2. **Container overlays on snapshot**: Colored dashed borders wrap groups of elements that belong to the same accessibility container (e.g. "Customers", "Project Details", "Project date")
3. **Container badges**: Small pill-shaped badges on the dashed container borders showing a layer icon + number
4. **Legend area (bottom)**: A hierarchical legend where:
   - Top-level elements get flat legend entries (badge + description)
   - Container groups are wrapped in a dashed colored border in the legend too
   - The container badge sits on the top border of the dashed group
   - Children of each container are listed inside the dashed group
   - The legend preserves the hierarchy visually

## Current Implementation State

### Architecture Overview

The container feature is controlled by `showContainers` on `AccessibilitySnapshotConfiguration` (defaults to `false`).

**Data flow:**
1. `AccessibilityHierarchyParser` parses the view tree into `[AccessibilityHierarchy]` — a recursive enum of `.element` and `.container` nodes
2. `HierarchyColorAssignment.build(from:)` assigns color indices:
   - Elements get sequential indices 0, 1, 2, ... matching flat traversal order
   - Containers get indices starting at `totalElements` (so they don't conflict with element colors)
3. The assigned hierarchy and flat `markers` array are both stored as state

### What's Implemented

#### 1. Container Overlay on Snapshot (`ContainerOverlayView.swift`)
- Renders a **dashed rounded-rect border** around the union of child element frames
- Has a `ContainerBadge` (layer icon + number) positioned on the top-left of the border
- Uses `entry.bounds` computed from `HierarchyColorAssignment.computeBounds()`
- Padding is applied via `containerPadding = 6` outset beyond element overlay outset

**However**: `ContainerOverlayView` exists as a standalone view but is **not currently rendered** in the snapshot overlay. Looking at `SwiftUIAccessibilitySnapshotView.swift`:
- `snapshotWithOverlays` only applies `.overlay(elementOverlayLayer)`
- `elementOverlayLayer` only renders `ElementOverlay` views from the flat `markers` array
- There is **no container overlay layer** being rendered on the snapshot image

The commit history confirms this: commit `3a282cdf` "Remove container overlay code, focus on legend only" explicitly removed container overlays from the snapshot.

#### 2. Hierarchical Legend (`HierarchyLegendView.swift`)
- Recursively renders `AssignedNode` tree
- Elements → `LegendEntryView` (badge + description + traits + etc.)
- Containers → `ContainerLegendEntryView` which renders:
  - A dashed border wrapping child entries
  - A `ContainerBadge` on the top-left of the border
  - Children laid out inside the dashed box

This **is wired up** in both `AccessibilitySnapshotView` and `PreParsedAccessibilitySnapshotView` — when `showContainers` is true and `colorAssignment` exists, `HierarchyLegendView` is used instead of the flat `LegendView`.

#### 3. Layout Behavior
- `PreParsedAccessibilitySnapshotView` has `legendOnRight` logic that returns `false` when `showContainers` is true (forces vertical/below layout)
- The `contentWidth` is `max(renderSize.width, LegendLayoutMetrics.minimumWidth)` but only applies to the non-container legend when in vertical layout

### Current Visual Output (from reference images)

**`testContainerDemo_26_4`**: Shows snapshot on top with element overlays only (no container dashed borders on the snapshot). Legend below shows flat entries — elements listed with badges 1-8, no container grouping visible. The hierarchical legend structure appears present but the containers themselves are not visually prominent.

**`testBasicAccessibilityDemoWithContainers_26_4`**: Similar — element overlays on snapshot, no container borders. Legend shows a hierarchical layout with container grouping — dashed borders around child entries visible.

### Gaps Between Current Implementation and Design Reference

1. **No container overlays on the snapshot image**: The design shows dashed colored borders wrapping groups on the screenshot itself. The code for this exists (`ContainerOverlayView.swift`) but was removed from the rendering pipeline in commit `3a282cdf`.

2. **Container overlay layer not wired**: `snapshotWithOverlays` only has `elementOverlayLayer`. To match the design, a second overlay layer using `ContainerOverlayView` needs to be drawn (either under or over element overlays).

3. **Legend hierarchy is working**: The `HierarchyLegendView` → `ContainerLegendEntryView` pipeline is functional and matches the design's hierarchical legend concept.

## Key Files

- `SwiftUIAccessibilitySnapshotView.swift` — Main view, orchestrates overlay + legend
- `ContainerOverlayView.swift` — Standalone dashed border + badge for snapshot overlay (not wired)
- `HierarchyColorAssignment.swift` — Assigns color indices, computes container bounds
- `HierarchyLegendView.swift` — Recursive legend rendering
- `ContainerLegendEntryView.swift` — Dashed-border legend entry for containers
- `ElementView.swift` — Element overlay (fill + stroke + badge) and `NumberBadge`
- `AccessibilitySnapshotConfiguration.swift` — `showContainers` flag
- `ContainerDemo.swift` — Test demo with UIKit containers

## Commit History (container-related)

1. `28096492` — Initial container visualization
2. `d776f45a` — Separate container overlays from element overlays
3. `dc7097e4` — Compute container bounds from child elements
4. `0783fb43` — Container badge with layer icon
5. `5bfce612` — Render container overlays separately
6. `c9d16183` — Draw elements first, containers on top
7. `1715dda5` — Fix container layout: left-align snapshot
8. `3a282cdf` — **Remove container overlay code, focus on legend only**
9. `5a9399fc` — Keep layout identical regardless of showContainers flag

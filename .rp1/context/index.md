# AccessibilitySnapshot - Codebase Knowledge Base

**Repository Type**: Single Project
**Primary Languages**: Swift, Objective-C
**Last Updated**: 2026-04-07
**Analysis Scope**: 148 files analyzed

## Quick Start

### Development Setup
```bash
git clone https://github.com/cashapp/AccessibilitySnapshot.git
cd AccessibilitySnapshot/Example
mise install
./Scripts/install-git-hooks.sh
tuist install
tuist generate
```

### Project Structure
```
Sources/AccessibilitySnapshot/
├── Parser/ObjC/                    # ObjC accessibility parsing layer
├── Parser/Swift/                   # Swift accessibility parsing classes
├── Core/                           # Core snapshot view rendering and layout
├── AccessibilitySnapshotPreviews/  # SwiftUI-based preview rendering
├── AccessibilityPreviews/          # Legacy SwiftUI preview support
├── SnapshotTesting/                # SnapshotTesting integration
└── iOSSnapshotTestCase/            # iOSSnapshotTestCase integration (Swift + ObjC)

Example/
├── AccessibilitySnapshot/                    # Demo app sources
├── AccessibilitySnapshotPreviewsDemo/        # Previews demo app
├── AccessibilitySnapshotPreviewsTests/       # Previews tests
├── SnapshotTests/                            # Snapshot regression tests
└── UnitTests/                                # Unit tests

Documentation/                                # Architecture docs and assets
```

### Entry Points
- **SnapshotTesting API**: `Sources/AccessibilitySnapshot/SnapshotTesting/SnapshotTesting+Accessibility.swift` - `.accessibilityImage` strategy
- **FBSnapshotTestCase API**: `Sources/AccessibilitySnapshot/iOSSnapshotTestCase/Swift/FBSnapshotTestCase+Accessibility.swift` - `SnapshotVerifyAccessibility`
- **Parser Engine**: `Sources/AccessibilitySnapshot/Parser/Swift/Classes/AccessibilityHierarchyParser.swift` - Core parsing
- **Core View (UIKit)**: `Sources/AccessibilitySnapshot/Core/AccessibilitySnapshotView.swift` - UIKit snapshot container
- **Core View (SwiftUI)**: `Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/SwiftUIAccessibilitySnapshotContainerView.swift` - SwiftUI rendering
- **Package Manifest**: `Package.swift` - SPM target definitions

### Key Commands
```bash
# Build
xcodebuild -scheme AccessibilitySnapshot -destination 'platform=iOS Simulator,name=iPhone 16'

# Test (English locale)
xcodebuild test -scheme 'AccessibilitySnapshotDemo (en)' -destination 'platform=iOS Simulator,name=iPhone 16'

# Tuist workflow
cd Example && tuist install && tuist generate

# Usage (SnapshotTesting)
assertSnapshot(matching: view, as: .accessibilityImage)

# Usage (FBSnapshotTestCase)
SnapshotVerifyAccessibility(view)
```

## Architecture Quick Reference
- **Pattern**: Layered library architecture (Parser → Core → Integration adapters)
- **Data Flow**: UIView → Parser extracts hierarchy → Core renders overlays + legend → Integration adapter captures snapshot
- **Key Technologies**: UIKit, SwiftUI, SnapshotTesting, iOSSnapshotTestCase, Tuist
- **Minimum Requirements**: iOS 13+, Xcode 13.2.1+, Swift 5.3+

## Development Workflow
1. Create feature branch from `main`
2. Run `tuist generate` in `Example/` to generate Xcode project
3. Implement changes with tests
4. Run snapshot tests to verify visual output
5. Update reference images if intentional visual changes
6. Submit PR for review

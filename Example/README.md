# Example Project

This is an example project that includes snapshot tests that are also used by the CI system to confirm the framework continues to work as expected.

## Development Requirements

Your local environment should match one of these supported configurations, which mirror the CI legs in [.github/workflows/ci.yml](https://github.com/cashapp/AccessibilitySnapshot/blob/main/.github/workflows/ci.yml) and the destinations in [Scripts/build.swift](https://github.com/cashapp/AccessibilitySnapshot/blob/main/Scripts/build.swift). Reference images are recorded per OS version and screen size, so tests only run on the simulators listed here.

| Xcode | Simulator | Host app / test scheme |
| --- | --- | --- |
| 15.4 | iOS 17.5 - iPhone 15 Pro | `AccessibilitySnapshotDemo (en)` |
| 16.4 | iOS 18.5 - iPhone 16 Pro | `AccessibilitySnapshotDemo (en)` |
| 26.2 | iOS 26.2 - iPhone 17 Pro | `AccessibilitySnapshotDemo (en)` (not run in CI) |
| 27.0 | iOS 27.0 - iPhone 18 Pro | `AccessibilitySnapshotDemoScenes (en)` |

Tuist is pinned in `mise.toml`; see the [Tuist installation docs](https://docs.tuist.io/guides/quick-start/install-tuist) for other ways to install it.

### Host apps

The snapshot and unit tests are hosted by a demo app, and the host app's life cycle affects how snapshots render: the snapshot functions host views in a window that UIKit only attaches to the app's scene in an app without a scene delegate. Apps built with the iOS 27 SDK must adopt the scene life cycle, so the Example builds two hosts from the same sources:

- **`AccessibilitySnapshotDemo`** — the app delegate owns the window. Hosts `SnapshotTests` and `UnitTests`. Use with Xcode 26 and earlier; built with the iOS 27 SDK it fails to launch.
- **`AccessibilitySnapshotDemoScenes`** — a scene delegate owns the window (`AccessibilitySnapshotScenes/`). Hosts `SnapshotTestsScenes` and `UnitTestsScenes`, which compile the same test sources. Use with Xcode 27 and later.

Both apps share the `AccessibilitySnapshotDemo` module name, so the tests' `@testable import AccessibilitySnapshotDemo` works with either host. FBSnapshotTestCase names reference-image folders after the test bundle, so the scene-hosted images live in `SnapshotTests/ReferenceImages/_64/SnapshotTestsScenes.*`.

All Example targets deploy to iOS 15.0, the minimum Xcode 27 accepts. The library itself still supports iOS 13.0.

### Setting up environment

1. Install the Xcode IDE

   - To install Xcode versions you can visit the [Apple developer downloads](https://developer.apple.com/download/all/) site directly.
   - Verify your Xcode version and installation with:

     ```sh
     xcode-select -p
     ```

1. Install Tuist

   ```sh
   curl -Ls https://install.tuist.io | bash
   ```

   Verify your installation:

   ```sh
   tuist version
   ```

### Building the project

1. This project uses [Mise](https://mise.jdx.dev/) and [Tuist](https://tuist.io/) to generate a project for local development. Follow the steps below for the recommended setup for zsh.

```sh
# install mise
brew install mise
# add mise activation line to your zshrc
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
# load mise into your shell
source ~/.zshrc
# tell mise to trust the config file
mise trust
# install dependencies
mise install
```
1. Generate the Xcode project using Tuist
```sh
# only necessary for first setup or after changing dependencies
tuist install --path Example
# generates and opens the Xcode project
tuist generate --path Example
```
1. Open the generated workspace

   ```sh
   open Example/AccessibilitySnapshot.xcworkspace
   ```
### Getting Snapshot Images from CI

Test results are archived for CI jobs. When there is a failure because of a snapshot test image changing those images can be extracted from the archive. See [Scripts/ExtractImagesFromTestResults.swift](https://github.com/cashapp/AccessibilitySnapshot/blob/main/Scripts/ExtractImagesFromTestResults.swift) for instructions.

### Recording reference images

Record mode is switched on per base class: `recordMode` in `SnapshotTests/SnapshotTestCase.swift` and `AccessibilitySnapshotPreviewsTests/AccessibilitySnapshotPreviewsTestCase.swift`, and `self.recordMode` in `SnapshotTests/ObjectiveCTests.m` and `SnapshotTests/ImpreciseObjectiveCTests.m`. The `SnapshotTestingTests` suite records missing images automatically. A new OS version also needs an entry in the `testedDevices` lists of both base classes.

Local renders can differ from the CI runners' by a few anti-aliased pixels. When a recorded image fails only on CI, prefer the CI render extracted from the test results.

### Testing on hardware

If you would like to run the demo app on a real device, add `export TUIST_DEVELOPMENT_TEAM=ABCDEFG123` (where `ABCDEFG123` is your Apple development team ID) to your `.zshrc` or `.bashrc` file. Alternatively, run the Tuist generation command as follows:
```sh
TUIST_DEVELOPMENT_TEAM=ABCDEFG123 tuist generate --path Example
```

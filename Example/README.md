# Example Project

This is an example project that includes snapshot tests that are also used by the CI system to confirm the framework continues to work as expected.

## Development Requirements

Your local environment should match one these supported versions.

| Software | Versions |
| --- | --- |
| Xcode | 12.5.1 (iOS 13 and 14), 14.3.1 (iOS 16) [.github/workflows/ci.yml](https://github.com/cashapp/AccessibilitySnapshot/blob/main/.github/workflows/ci.yml) |
| Tuist | See [Tuist installation docs](https://docs.tuist.io/guides/quick-start/install-tuist) |
| Simulators | iOS 16.4, iOS 17.2 - iPhone 14 Pro [Scripts/build.swift](https://github.com/cashapp/AccessibilitySnapshot/blob/main/Scripts/build.swift) |

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

### Testing on hardware

If you would like to run the demo app on a real device, add `export TUIST_DEVELOPMENT_TEAM=ABCDEFG123` (where `ABCDEFG123` is your Apple development team ID) to your `.zshrc` or `.bashrc` file. Alternatively, run the Tuist generation command as follows:
```sh
TUIST_DEVELOPMENT_TEAM=ABCDEFG123 tuist generate --path Example
```

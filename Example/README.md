# Example Project

This is an example project that includes snapshot tests that are also used by the CI system to confirm the framework continues to work as expected.

## Development Requirements

Your local environment should match one these supported versions.

| Software | Versions |
| --- | --- |
| Xcode | 12.5.1 (iOS 13 and 14), 14.3.1 (iOS 16) [.github/workflows/ci.yml](https://github.com/cashapp/AccessibilitySnapshot/blob/master/.github/workflows/ci.yml) |
| Ruby | 3.2.2 [Example/Gemfile](https://github.com/cashapp/AccessibilitySnapshot/blob/master/Example/Gemfile) |
| Bundler | 2.4.22 [Gemfile.lock](https://github.com/cashapp/AccessibilitySnapshot/blob/master/Gemfile.lock) |
| Simulators | iOS 13.7 - iPhone 12 Pro, iOS 14.5 - iPhone 12 Pro, iOS 16.4 - iPhone 14 Pro [Scripts/build.swift](https://github.com/cashapp/AccessibilitySnapshot/blob/master/Scripts/build.swift) |

### Setting up environment

1. Install the Xcode IDE

   - To install Xcode versions you can visit the [Apple developer downloads](https://developer.apple.com/download/all/) site directly.
   - Verify your Xcode version and installation with:

     ```sh
     xcode-select -p
     ```

1. RVM can be used for Ruby version management. Instructions here: https://rvm.io/rvm/install

   - Install the current Ruby version

     ```sh
     rvm install ruby-3.2.2 --with-openssl-dir=/opt/homebrew/opt/openssl@3
     ```

     NOTE: This can take a while as RVM will typically build Ruby from source.

   - Restart your shell session after installing RVM and Ruby or: `source ~/.zshrc` / `source ~/.bashrc`

   - Verify your installation of RVM and Ruby

     ```sh
     which ruby # /Users/<LDAP>/.rvm/rubies/ruby-3.2.2/bin/ruby
     ```

1. Install Bundler

     ```sh
     gem install bundler -v 2.4.22
     ```

    Verify your installation of Bundler

     ```sh
     bundle -v # Bundler version 2.4.22
     ```

### Building the project

1. Install the required Gems in the `Gemfile`

    ```sh
    bundle install
    ```

1. Install CocoaPod dependencies from `Podfile` and update the CocoaPod source repositories

   ```sh
   bundle exec pod install
   ```

1. Open the newly generated workspace

   ```sh
   xed AccessibilitySnapshot.xcworkspace
   ```

### Getting Snapshot Images from CI

Test results are archived for CI jobs. When there is a failure because of a snapshot test image changing those images can be extracted from the archive. See [Scripts/ExtractImagesFromTestResults.swift](https://github.com/cashapp/AccessibilitySnapshot/blob/master/Scripts/ExtractImagesFromTestResults.swift) for instructions.

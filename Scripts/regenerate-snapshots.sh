#!/bin/bash
#
# Regenerates all snapshot reference images using the exact device models from CI.
#
# Usage:
#   Scripts/regenerate-snapshots.sh           # Regenerate on all CI devices
#   Scripts/regenerate-snapshots.sh iOS_18    # Regenerate on a single platform
#
# The device matrix mirrors .github/workflows/ci.yml

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE_DIR="$REPO_ROOT/Example"
WORKSPACE="$EXAMPLE_DIR/AccessibilitySnapshot.xcworkspace"
SCHEME="AccessibilitySnapshotDemo (en)"
SNAPSHOT_TEST_CASE="$EXAMPLE_DIR/SnapshotTests/SnapshotTestCase.swift"

# CI device matrix — keep in sync with .github/workflows/ci.yml
# Format: device_type|os_version
# Device types match SimDeviceType identifiers (without the com.apple.CoreSimulator.SimDeviceType. prefix)
platform_config() {
    case "$1" in
        iOS_17) echo "iPhone-15-Pro|17.5" ;;
        iOS_18) echo "iPhone-16-Pro|18.5" ;;
        iOS_26) echo "iPhone-17-Pro|26.2" ;;
        *) echo "" ;;
    esac
}

ALL_PLATFORMS="iOS_17 iOS_18 iOS_26"

# Find a simulator UDID by device type and OS version
find_simulator() {
    local device_type="$1"
    local os_version="$2"
    local os_dashed="${os_version//./-}"
    local device_type_id="com.apple.CoreSimulator.SimDeviceType.${device_type}"

    xcrun simctl list devices -j 2>/dev/null \
        | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if runtime.endswith('iOS-${os_dashed}'):
        for d in devices:
            if d.get('isAvailable', False) and d.get('deviceTypeIdentifier') == '${device_type_id}':
                print(d['udid'])
                sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

# Parse arguments
if [ $# -eq 0 ]; then
    PLATFORMS="$ALL_PLATFORMS"
else
    PLATFORMS="$*"
fi

echo "=== Snapshot Reference Image Regeneration ==="
echo "Platforms: $PLATFORMS"
echo ""

# Ensure workspace exists
if [ ! -d "$WORKSPACE" ]; then
    echo "Workspace not found. Running tuist generate..."
    (cd "$EXAMPLE_DIR" && tuist install && tuist generate --no-open)
fi

# Enable record mode by modifying source (reverted on exit)
enable_record_mode() {
    sed -i '' 's/recordMode = false/recordMode = true/' "$SNAPSHOT_TEST_CASE"
    echo "Record mode enabled"
}

disable_record_mode() {
    sed -i '' 's/recordMode = true/recordMode = false/' "$SNAPSHOT_TEST_CASE"
    echo "Record mode disabled"
}

# Always revert record mode on exit
trap disable_record_mode EXIT

enable_record_mode

for platform in $PLATFORMS; do
    config="$(platform_config "$platform")"

    if [ -z "$config" ]; then
        echo "Unknown platform: $platform"
        echo "Valid platforms: $ALL_PLATFORMS"
        exit 1
    fi

    device_type="${config%%|*}"
    os="${config##*|}"
    device_label="${device_type//-/ }"

    echo "--- Recording on $device_label (iOS $os) ---"

    udid="$(find_simulator "$device_type" "$os" || true)"
    if [ -z "$udid" ]; then
        echo "No simulator found for $device_type with iOS $os"
        echo "Create one with: xcrun simctl create '$device_label' com.apple.CoreSimulator.SimDeviceType.$device_type com.apple.CoreSimulator.SimRuntime.iOS-${os//./-}"
        exit 1
    fi

    echo "Using simulator: $udid"

    # Record mode tests "fail" because FBSnapshotTestCase reports
    # "Test ran in record mode" as a test failure. This is expected.
    xcodebuild test \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$udid" \
        -only-testing:SnapshotTests \
        2>&1 | grep -E "Reference image save|Test Suite .*(passed|failed)|TEST (SUCCEEDED|FAILED)" || true

    echo ""
done

echo "=== Done ==="
echo ""
echo "Review the changes with:"
echo "  git diff --stat -- Example/SnapshotTests/ReferenceImages/ Example/SnapshotTests/__Snapshots__/"

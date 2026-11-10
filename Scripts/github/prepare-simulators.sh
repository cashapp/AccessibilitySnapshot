#!/bin/bash -l
set -ex

IFS=','; PLATFORMS=$(echo $1); unset IFS

sudo mkdir -p /Library/Developer/CoreSimulator/Profiles/Runtimes

if [[ ${PLATFORMS[*]} =~ 'iOS_16' ]]; then
	sudo ln -s /Applications/Xcode_14.3.1.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ 16.4.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'iOS_17' ]]; then
	xcodebuild -runFirstLaunch
	xcrun simctl list runtimes > /dev/null
	# The 7 GB download from Apple sometimes drops partway through, so retry it.
	# Its progress output runs to tens of thousands of lines, so show only the end.
	download_log=$(mktemp)
	for attempt in 1 2 3; do
		xcodebuild -downloadPlatform iOS -buildVersion 17.5 > "$download_log" 2>&1 && tr "\r" "\n" < "$download_log" | tail -n 1 && break
		tr "\r" "\n" < "$download_log" | tail -n 20
		[[ $attempt == 3 ]] && exit 1
		sleep 10
	done
	# CoreSimulator creates the runtime's default devices a few seconds after the download finishes.
	for _ in {1..30}; do
		xcrun simctl list devices 'iOS 17.5' | grep -q 'iPhone 15 Pro (' && break
		sleep 1
	done
	xcrun simctl list devices 'iOS 17.5' | grep -q 'iPhone 15 Pro (' || xcrun simctl create 'iPhone 15 Pro' 'iPhone 15 Pro' com.apple.CoreSimulator.SimRuntime.iOS-17-5
fi

xcrun simctl list runtimes

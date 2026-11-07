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
	for attempt in 1 2 3; do
		xcodebuild -downloadPlatform iOS -buildVersion 17.5 && break
		[[ $attempt == 3 ]] && exit 1
		sleep 10
	done
	xcrun simctl list devices 'iOS 17.5' | grep -q 'iPhone 15 Pro (' || xcrun simctl create 'iPhone 15 Pro' 'iPhone 15 Pro' com.apple.CoreSimulator.SimRuntime.iOS-17-5
fi

xcrun simctl list runtimes

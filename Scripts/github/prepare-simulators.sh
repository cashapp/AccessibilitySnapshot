#!/bin/bash -l
set -ex

IFS=','; PLATFORMS=$(echo $1); unset IFS

sudo mkdir -p /Library/Developer/CoreSimulator/Profiles/Runtimes

if [[ ${PLATFORMS[*]} =~ 'iOS_15' ]]; then
    sudo ln -s /Applications/Xcode_13.2.1.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ 15.2.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'iOS_14' ]]; then
    sudo ln -s /Applications/Xcode_12.5.1.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ 14.5.simruntime
fi

if [[ ${PLATFORMS[*]} =~ 'iOS_13' ]]; then
	sudo ln -s /Applications/Xcode_11.7.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ 13.7.simruntime
fi

xcrun simctl list runtimes

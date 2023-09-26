#!/bin/bash -l
# set -ex

# Usage:
#
# 1. Download the Test Results bundle from the CI build. From your PR, go to
#    Checks > CI, then click on "Test Results" in the Artifacts section.
#
# 2. Run this script with the path to this download.
#
#		./Scripts/ExtractImagesFromTestResults.sh /path/to/Test\ Results
#
# 3. This will create a directory called "tmp" that contains all of the
#    extracted images (reference, failed, and diff) organized by OS version,
#	 test class name, and test name.

IFS=$'\n'
for path in $(find "$1" -iname "*.xcresult"); do
	xcparse screenshots --os --test "$path" tmp
done
unset IFS

#!/bin/bash -l
set -e

# Find the directory in which this script resides.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

actionstr=$(echo $ACTIONS | tr "," "\n")
for action in $actionstr ; do
	case $action in
	xcode)
		$DIR/build.swift xcode $PLATFORM `which xcpretty`
		;;

	pod-lint)
		bundle exec --gemfile=Example/Gemfile pod lib lint --verbose --fail-fast
		;;
	esac
done

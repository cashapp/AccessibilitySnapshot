#!/usr/bin/swift

// This script is designed to make it easier to review a large number of snapshot reference images that have been
// recorded on a new iOS version, for which git does not identify the files as renames. It requires having Kaleidoscope
// installed, including the ksdiff utility.
//
// Here is a sample workflow for updating reference images:
//
// 1. Add a new worktree and check out the commit that contains the most recent version of the old snapshots.
//
//     git worktree add ../AccessibilitySnapshot-snapshots-old <commit>
//
// 2. On your main worktree, add the new snapshots you wish to review.
//
// 3. Copy the image paths from the staging area to a text file.
//
// 4. Run this script with the appropriate paths and the relevant versions. For example, when updating snapshots from
//    iOS 13.1 to 13.2.2, this would be:
//
//     ./Scripts/CompareRenamedSnapshots.swift /path/to/image/list.txt ../AccessibilitySnapshot-snapshots-old 13.2.2 13.1
//
// The script will open Kaleidoscope with each image pair in sequence (when you close one diff, the next will open).

import Foundation

enum TaskError: Error {
	case code(Int32)
}

func execute(commandPath: String, arguments: [String]) throws {
	let task = Process()
	task.launchPath = commandPath
	task.arguments = arguments

	task.launch()

	task.waitUntilExit()

	guard task.terminationStatus == 0 else {
		throw TaskError.code(task.terminationStatus)
	}
}

if CommandLine.arguments.count < 5 || CommandLine.arguments[1] == "--help" || CommandLine.arguments[1] == "-h" {
	print("usage: CompareRenamedSnapshots SNAPSHOT_LIST_FILE OLD_REPO_PATH NEW_DEVICE_ID OLD_DEVICE_ID")
	exit(0)
}

let snapshotListFilePath = CommandLine.arguments[1]
let snapshotImageList = String(data: NSData(contentsOfFile: snapshotListFilePath)! as Data, encoding: .utf8)!.split(separator: "\n")

let oldRepoPath = CommandLine.arguments[2]

let newDeviceId = CommandLine.arguments[3]
let oldDeviceId = CommandLine.arguments[4]
let newDeviceIdFBSnapshotTestCase = newDeviceId.replacingOccurrences(of: ".", with: "_")
let oldDeviceIdFBSnapshotTestCase = oldDeviceId.replacingOccurrences(of: ".", with: "_")
let newDeviceIdSnapshotTesting = newDeviceId.replacingOccurrences(of: ".", with: "-")
let oldDeviceIdSnapshotTesting = oldDeviceId.replacingOccurrences(of: ".", with: "-")

func ksdiff(oldFilePath: String, newFilePath: String, index: Int) throws {
	guard newFilePath.contains(newDeviceIdFBSnapshotTestCase) || newFilePath.contains(newDeviceIdSnapshotTesting) else {
		print("Skipping \(newFilePath) since there is it is of an unknown version")
		return
	}

	print("Showing diff for \(newFilePath) (\(index+1) of \(snapshotImageList.count))")

	try execute(
		commandPath: "/usr/local/bin/ksdiff",
		arguments: ["--wait", oldFilePath, newFilePath]
	)
}

for (index, newFilePath) in snapshotImageList.enumerated() {
	let oldFilePathInRepo = String(
		newFilePath
			.replacingOccurrences(of: newDeviceIdFBSnapshotTestCase, with: oldDeviceIdFBSnapshotTestCase)
			.replacingOccurrences(of: newDeviceIdSnapshotTesting, with: oldDeviceIdSnapshotTesting)
	)

	do {
		try ksdiff(oldFilePath: oldRepoPath + "/" + oldFilePathInRepo, newFilePath: String(newFilePath), index: index)
	} catch {
		print("Failed to diff \(newFilePath)")
	}
}

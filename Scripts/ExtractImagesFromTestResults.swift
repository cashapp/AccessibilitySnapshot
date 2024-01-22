#!/usr/bin/swift

// Usage:
//
// 1. Install xcparse: brew install chargepoint/xcparse/xcparse
//
// 2. Download the Test Results bundle from the CI build. From your PR, go to
//    Checks > CI, then click on "Test Results" in the Artifacts section.
//
// 3. Run this script with the path to this download.
//
//		./Scripts/ExtractImagesFromTestResults.swift /path/to/Test\ Results
//
// 4. This will create a directory called "tmp" that contains all of the
//    extracted images (reference, failed, and diff) organized by OS version,
//	  test class name, and test name.

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

if CommandLine.arguments.count < 2 || CommandLine.arguments[1] == "--help" || CommandLine.arguments[1] == "-h" {
    print("usage: CompareRenamedSnapshots SNAPSHOT_LIST_FILE OLD_REPO_PATH NEW_DEVICE_ID OLD_DEVICE_ID")
    exit(0)
}

let testResultsContainerPath = CommandLine.arguments[1]
let testResultsContainerURL = URL(filePath: testResultsContainerPath)

let fileManager = FileManager.default
guard let testResultsEnumerator = fileManager.enumerator(at: testResultsContainerURL, includingPropertiesForKeys: [URLResourceKey.nameKey], options: .skipsHiddenFiles) else {
    exit(1)
}

func parseResults(testResultsPath: String, outputPath: String) throws {
    try execute(
        commandPath: "/opt/homebrew/bin/xcparse",
        arguments: ["screenshots", "--os", "--test", testResultsPath, outputPath]
    )
}

for case let fileURL as URL in testResultsEnumerator {
    if fileURL.path.hasSuffix(".xcresult") {
        try parseResults(testResultsPath: fileURL.path, outputPath: "tmp")
    }
}

/*

 As a future enhancement, this script could also rename the failed snapshot images. One complicating
 factor of this is the tests with multiple associated reference images (e.g. when using identifiers)
 don't differentiate the resulting images in the test result bundle. We'll also need to handle
 renaming based on which snapshot engine was used:

    FBSnapshotTestCase

        /Example/SnapshotTests/ReferenceImages/_64/<TestClass>/

            <TestName>_14_5_390x844@3x.png
            <TestName>_13_7_375x812@3x.png

    SnapshotTesting

        /Example/SnapshotTests/__Snapshots__/<TestClass>/

            <TestName>.390x844-14-5-3x.png
            <TestName>.375x812-13-7-3x.png

 */


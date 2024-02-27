#!/usr/bin/swift

import Foundation
import RegexBuilder

let fileManager = FileManager.default

guard let enumerator = fileManager.enumerator(
    atPath: (fileManager.currentDirectoryPath as NSString)
        .appendingPathComponent("Sources")
) else {
    exit(1)
}

var swiftFiles: [String] = []
var stringsFiles: [String] = []

for filePath in enumerator {
    let filePath = filePath as! String
    if filePath.hasSuffix(".swift") {
        swiftFiles.append("Sources/\(filePath)")
    } else if filePath.hasSuffix(".strings") {
        stringsFiles.append("Sources/\(filePath)")
    }
}

print("Found source files:")
swiftFiles.forEach { print("  \($0)")}

print("Found strings files:")
stringsFiles.forEach { print("  \($0)")}

let localizedStringRegex = Regex {
    "localized("
    ZeroOrMore(.whitespace)
    "key:"
    ZeroOrMore(.whitespace)
    "\""
    Capture {
        OneOrMore(.any.subtracting(.anyOf("\"")))
    }
    "\""
}

let localizedKeys = try swiftFiles.flatMap { filePath in
    return try String(contentsOfFile: filePath)
        .matches(of: localizedStringRegex)
        .map { $0.1 }
}

let localizedKeysSet = Set(localizedKeys)

if localizedKeysSet.count != localizedKeys.count {
    print("❌ There is a repeated localized string key")
    exit(1)
}

let translationRegex = Regex {
    Anchor.startOfLine
    "\""
    Capture {
        OneOrMore(.any.subtracting(.anyOf("\"")))
    }
}

var allValid = true

for filePath in stringsFiles {
    let translationKeys = try Set(String(contentsOfFile: filePath).matches(of: translationRegex).map { $0.1 })

    if translationKeys != localizedKeysSet {
        print("❌ \(filePath) does not match expected set of localized string keys")
        let expected = translationKeys.subtracting(localizedKeysSet)
        if expected.count != 0 {
            print("Expected Keys not found: \(expected)")
        }
        let found = localizedKeysSet.subtracting(translationKeys)
        if found.count != 0 {
            print("No translation found for keys: \(found)")
        }
        allValid = false
    }
}

exit(allValid ? 0 : 1)

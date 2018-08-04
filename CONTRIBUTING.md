Contributions to AccessibilitySnapshot are welcomed and greatly appreciated!

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://tools.ietf.org/html/rfc2119).

### Sign the CLA

All contributors to your PR must sign our [Individual Contributor License Agreement (CLA)](https://spreadsheets.google.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1). The CLA is a short form that ensures that you are eligible to contribute.

### Start with an Issue

If you want to add a feature or report a bug, please file an [Issue](https://github.com/CashApp/AccessibilitySnapshot/issues) first. An Issue gives us the opportunity to discuss the requirements and implications of a feature with you before you start writing code. This also gives other users an opportunity to search for issues similar to theirs.

### Submitting a Pull Request

Keep your Pull Requests small. Small PRs are easier to reason about, which makes them significantly more likely to get merged.

All PRs that change functionality must include tests. Changes that affect the ouput of an accessibility snapshot test should include a snapshot test, either in the form of an added test for new functionality or updated reference snapshots for changed functionality. For non-visual changes that are not easily represented by a snapshot test, or changes that involve complex logic more easily represented by text, a unit test should be used.

### Backwards compatibility

Respect the minimum deployment target. If you are adding code that uses new APIs, you must prevent older clients from crashing or misbehaving. Our CI runs against our minimum deployment targets, so you will not get a green build unless your code is backwards compatible.

### Forwards compatibility

New code should not use deprecated APIs.

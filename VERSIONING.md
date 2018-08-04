Versioning for AccessibilitySnapshot follows the [Semantic Versioning](https://semver.org/) specification, with a few notable changes that promote some forms of modification to a major version change.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://tools.ietf.org/html/rfc2119).

### Beta Versioning

AccessibilitySnapshot is currently in beta development. Until the 1.0 release, the versioning rules in the rest of this document are adjusted such that:

* The MAJOR version is always 0.
* A breaking change (a change that would usually increment the MAJOR version) increments the MINOR version.
* All other changes (changes that would usually increment the MINOR or PATCH version) increment the PATCH version.

### Versioning Philosophy

As a testing framework, the versioning for AccessibilitySnapshot works such that for consumers:

* Updating to a version that differs in PATCH version only is guaranteed to compile and pass tests.
* Updating to a version that differs in MINOR and PATCH version only is guaranteed to compile, and is guaranteed to pass tests if the contents of the tests were correct originally.
* Updating to a version that differs in MAJOR version is not guaranteed to compile or pass tests.

### Modifications to Snapshot Format

Any modifications to the format of a snapshot image shall result in a MAJOR version change, since format differences will cause tests to fail.

### Correcting Accessibility Element Descriptions

Modifications that add support for elements whose descriptions previously did not match the output of VoiceOver do not require a MAJOR version change. Best practice for snapshot testing is to disable (or purposefully exclude) tests that reflect incorrect behavior. Therefore, although any reference snapshots that did include the previously incorrect description will fail, these tests should not have been included in the first place.

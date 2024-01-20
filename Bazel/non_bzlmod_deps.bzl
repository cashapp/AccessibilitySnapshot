"""Defines extensions and macros for MODULE.bazel"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# -- Non-bzlmod versions

IOS_SNAPSHOT_TEST_CASE_VERSION = "57b023c8bb3df361e2fae01532cd066ec0b65d2e"  # NOTE: this is 8.0.0 with some Bazel build fixes
SWIFT_SNAPSHOT_TESTING_VERSION = "1.8.2"

# -- Module extension

def non_bzlmod_repositories():
    """Defines external dependencies which do not support bzlmod"""

    http_archive(
        name = "ios_snapshot_test_case",
        url = "https://github.com/uber/ios-snapshot-test-case/archive/%s.zip" % IOS_SNAPSHOT_TEST_CASE_VERSION,
        strip_prefix = "ios-snapshot-test-case-%s" % IOS_SNAPSHOT_TEST_CASE_VERSION,
        sha256 = "fae7ec6bfdc35bb026a2e898295c16240eeb001bed188972ddcc0d7dc388cda3",
        patches = ["//Bazel:0001-Patch-testonly-swift_library.patch"],
        patch_args = ["-p1"],
    )

    http_archive(
        name = "swift_snapshot_testing",
        url = "https://github.com/pointfreeco/swift-snapshot-testing/archive/refs/tags/%s.tar.gz" % SWIFT_SNAPSHOT_TESTING_VERSION,
        strip_prefix = "swift-snapshot-testing-%s" % SWIFT_SNAPSHOT_TESTING_VERSION,
        sha256 = "f924de0b1e326b108120593e802cd0b6577edf7fbb8a87c6841a428722d3b14d",
        build_file = "//Bazel:swift_snapshot_testing.BUILD.bazel",
    )

def _non_bzlmod_deps_impl(_):
    non_bzlmod_repositories()

non_bzlmod_deps = module_extension(
    implementation = _non_bzlmod_deps_impl,
)

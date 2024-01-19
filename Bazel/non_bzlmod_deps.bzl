"""Defines extensions and macros for MODULE.bazel"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# -- Non-bzlmod versions

IOS_SNAPSHOT_TEST_CASE_VERSION = "57b023c8bb3df361e2fae01532cd066ec0b65d2e"

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

def _non_bzlmod_deps_impl(_):
    non_bzlmod_repositories()

non_bzlmod_deps = module_extension(
    implementation = _non_bzlmod_deps_impl,
)

# AccessibilitySnapshot Release

AccessibilitySnapshot releases are cut from `main` and use annotated Git tags whose name matches the version in `RELEASE-VERSION`, such as `0.11.0`.

## 1. Update RELEASE-VERSION

- Review [VERSIONING.md](VERSIONING.md) and choose the next version.

1. Branch from `origin/main`.
2. Update `RELEASE-VERSION` so it contains only the new version number.
3. Open and merge a pull request for that change.

## 2. Tag the merged release commit

1. Fetch the latest refs and tags.
2. Find the commit on `origin/main` that added the new `RELEASE-VERSION`.
3. Verify that commit contains the expected version.
4. Create and push an annotated tag with the same version number.

## 3. Prepare the draft release

Create the GitHub release as a draft with a changelog including all the PRs that are in the release.

## 4. Publish

After reviewing the draft, publish the release from GitHub.

# Cutting a new release

1. Bump the version in `lib/jupiter/version.rb`.
2. Update and verify CHANGELOG.md to ensure any changes made to project since last release are captured in the changelog.
3. Create a new version section at the top of the changelog just after the `## [Unreleased]` section. Using the format of `## [X.Y.Z] - 20XX-01-01`
4. Commit your changes and push up a new pull request.
5. Once reviewed and merged, draft a new release in Github under https://github.com/ualbertalib/jupiter/releases/new.
  - Choose a new tag using the format of `jupiter-X.Y.Z`
  - Give it a meaningful title and description. Most likely want to copy the changelog notes for this release into the description
  - Set this release as "the latest release"
6. Publish the release!

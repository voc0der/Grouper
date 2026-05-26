# Release Process

Canonical release instructions live in [RELEASING.md](../RELEASING.md).

## Automated Process

Every push to `main` runs the tag workflow:

- Reads `## Version:` from `Grouper.toc`
- Creates `v<version>` if that tag does not already exist
- Tag pushes trigger the BigWigs packager release workflow
- The release workflow verifies runtime-only package contents before upload

The workflow does not auto-increment versions. Bump `Grouper.toc`, `Grouper.lua`, and `CHANGELOG.md` intentionally before merging a release commit.

## PR Artifacts

Pull requests run the package workflow and tests. Add the `build` label to have the companion workflow post a downloadable addon artifact comment on the PR.

## Quick Checklist

- [ ] Update `CHANGELOG.md` under `[Unreleased]`
- [ ] Run `luac -p Grouper.lua tests/run.lua`
- [ ] Run `lua tests/run.lua`
- [ ] Run `bash ./.github/scripts/verify-release-package.sh` for packaging changes
- [ ] Bump version metadata when preparing an actual release
- [ ] Push or merge to `main` and verify the tag/release workflows

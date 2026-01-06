# Release Process

## Automated Process

Every push to `main` triggers an automatic release via GitHub Actions:
- Auto-increments the patch version (e.g., v1.0.12 → v1.0.13)
- Extracts release notes from CHANGELOG.md [Unreleased] section
- Creates a GitHub release with formatted notes
- Builds and attaches `Grouper.zip` to the release

**The release notes come directly from CHANGELOG.md**, so keep the [Unreleased] section updated!

## Manual Steps (For Major/Minor Releases or Enhanced Notes)

### 1. Update CHANGELOG.md

Before committing changes, update [CHANGELOG.md](../CHANGELOG.md):

```markdown
## [Unreleased]

### Added
- New feature description

### Changed
- Changed feature description

### Fixed
- Bug fix description
```

### 2. Commit and Push

```bash
git add CHANGELOG.md
git commit -m "Update changelog for release"
git push
```

### 3. Create Manual Release (Optional)

If you want custom release notes instead of auto-generated:

1. Go to https://github.com/voc0der/Grouper/releases
2. Click "Draft a new release"
3. Choose the auto-created tag or create a new one
4. Copy content from CHANGELOG.md [Unreleased] section
5. Use [RELEASE_TEMPLATE.md](RELEASE_TEMPLATE.md) as a guide
6. Publish release

### 4. Update CHANGELOG.md After Release

Move [Unreleased] content to a new version section:

```markdown
## [Unreleased]

## [1.0.13] - 2026-01-05

### Added
- Feature that was added

[Unreleased]: https://github.com/voc0der/Grouper/compare/v1.0.13...HEAD
[1.0.13]: https://github.com/voc0der/Grouper/releases/tag/v1.0.13
```

## Version Numbering

Following [Semantic Versioning](https://semver.org/):
- **MAJOR** (v2.0.0): Breaking changes, incompatible API changes
- **MINOR** (v1.1.0): New features, backwards-compatible
- **PATCH** (v1.0.1): Bug fixes, backwards-compatible

## Quick Checklist

- [ ] Update CHANGELOG.md with changes
- [ ] Test the addon in-game
- [ ] Commit changes with descriptive message
- [ ] Push to main (triggers auto-release)
- [ ] Verify release on GitHub
- [ ] Update CHANGELOG.md to move [Unreleased] to new version

# Releasing to CurseForge

## Multi-Expansion Support

Grouper supports Classic, TBC, and WOTLK in a single addon package. The TOC file specifies multiple interface versions:

```
## Interface: 11507, 20505, 30403
```

This tells CurseForge to create separate downloads for each game version automatically.

## Release Process

### Option 1: GitHub Releases (Automated via CurseForge)

1. Update version in `Grouper.toc` and `Grouper.lua`
2. Update `CHANGELOG.md` with release notes
3. Commit and push to GitHub:
   ```bash
   git add -A
   git commit -m "Release v1.0.X"
   git tag v1.0.X
   git push origin main --tags
   ```
4. CurseForge will automatically pick up the tag and create releases for all three expansions

### Option 2: Manual Upload to CurseForge

1. Create a zip file of the addon:
   ```bash
   cd /home/vocoder/Code
   zip -r Grouper-v1.0.X.zip Grouper -x "*.git*" -x "*README.md"
   ```
2. Go to [CurseForge Project Page](https://www.curseforge.com/wow/addons/grouper/files)
3. Upload the zip file
4. CurseForge will automatically create separate downloads for:
   - Classic (11507)
   - TBC (20505)
   - WOTLK (30403)

### Option 3: Using CF CLI

If you have the CurseForge CLI tool:
```bash
cf-cli upload --project-id 1421970 --version 1.0.X
```

## What Gets Released

The `.pkgmeta` file controls what gets included:
- ✅ Grouper.lua
- ✅ Grouper.toc
- ✅ CHANGELOG.md
- ❌ README.md (excluded)
- ❌ .git files (excluded)

## Automatic Features

CurseForge will:
- Create separate downloads for each game version
- Parse the CHANGELOG.md for release notes
- Set the correct game version compatibility automatically
- List all three versions on the addon page

## Version Numbering

Follow semantic versioning: `MAJOR.MINOR.PATCH`
- MAJOR: Breaking changes
- MINOR: New features
- PATCH: Bug fixes

Current version: 1.0.42

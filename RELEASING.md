# Releasing to CurseForge

## Multi-Expansion Support

Grouper supports Classic Era, TBC Anniversary Classic, and Wrath Classic in a single unified addon. The TOC file specifies multiple interface versions:

```text
## Interface: 11507, 20505, 30403
```

Players on any supported Classic client download the same package.

## Workflow Prerequisites

Before automated release can work end-to-end, configure:

1. GitHub Actions secret `RELEASE_PAT`
   - Fine-grained token with repository `Contents: Read and write`
   - Needed so tag push can trigger the release workflow
2. GitHub Actions secret `CF_API_KEY`
   - CurseForge API token used by `BigWigsMods/packager`
3. CurseForge project metadata in addon TOC / `.pkgmeta`
   - `## X-Curse-Project-ID: 1421970`
   - `curse-project-id: 1421970`
   - Project page: `https://www.curseforge.com/wow/addons/grouper`

## Release Process

### Automated (GitHub Actions)

1. Update version in `Grouper.toc` and `Grouper.lua`
2. Update `CHANGELOG.md` with release notes
3. Commit and push to `main`
4. CI automatically creates a tag from the TOC version and triggers the packager

### PR Build Artifacts

- Add the `build` label to a pull request when you want the PR packaging workflows to post a downloadable addon zip artifact comment for that PR head commit.

### Troubleshooting

- No new tag created:
  - Check `## Version:` in `Grouper.toc` is bumped, for example `1.0.49`
  - If tag already exists, for example `v1.0.49`, workflow will skip by design
- Tag created but no CurseForge upload:
  - Confirm `CF_API_KEY` exists in repo secrets
  - Confirm `## X-Curse-Project-ID:` and `.pkgmeta` project metadata are set to valid numeric project IDs
- Tag workflow failing authentication:
  - Confirm `RELEASE_PAT` exists and has repo contents write permissions
  - If using org SSO, ensure the token is authorized for the org

### Manual Upload to CurseForge

1. Create a zip file:
   ```bash
   cd /home/vocoder/Code/Grouper
   rm -rf dist
   bash ./.github/scripts/stage-addon.sh dist/Grouper
   cd dist
   zip -r Grouper-v1.0.X.zip Grouper
   ```
2. Upload at the CurseForge project files page.

## What Gets Released

Only runtime addon files should ship to players.

The PR package workflow stages files directly from `Grouper.toc`, and the release workflow verifies that `.pkgmeta` produces the same runtime-only tree before uploading to GitHub and CurseForge.

For the current addon, the packaged game files are:

- `Grouper.toc`
- `Grouper.lua`

Non-game files such as `tests/`, docs, and repo metadata must stay out of the final addon archive.

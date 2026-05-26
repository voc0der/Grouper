# Contributing

Thanks for working on `Grouper`.

This addon helps Classic-era raid leaders recruit and organize PUG groups. Changes should stay focused on practical raid-management workflows, clear in-game explanations, and runtime-safe WoW API usage.

## Local Setup

- Target clients: Classic Era, TBC Anniversary Classic, and Wrath Classic
- Addon install path: `World of Warcraft/_classic_/Interface/AddOns/`
- Runtime files are listed in [Grouper.toc](Grouper.toc)

## Development

Keep a local Blizzard UI mirror at `../wow-ui-source`. If you do not already have it checked out:

```bash
git clone https://github.com/Gethe/wow-ui-source ../wow-ui-source
```

Refresh the Blizzard UI reference before you start work:

```bash
git -C ../wow-ui-source pull --ff-only
```

Use `../wow-ui-source` first for TOC, interface number, FrameXML, raid roster APIs, protected action behavior, popup/menu behavior, and Blizzard UI/API questions before changing addon code or guessing at client behavior.

Run the local test suite:

```bash
lua tests/run.lua
```

Run a syntax check before opening a PR:

```bash
luac -p Grouper.lua tests/run.lua
```

If you change packaging or release behavior, also verify the runtime-only package contents:

```bash
bash ./.github/scripts/verify-release-package.sh
```

## Project Expectations

- Keep the addon useful in real PUG conditions: prefer robust scoring, explanations, and low churn over brittle perfect-composition assumptions.
- Respect raid-leader agency. Features that move players should preview changes first and require leader/assistant authority before applying.
- Prefer source-verified Classic/TBC/Wrath APIs when touching raid movement, role assignment, FrameXML templates, or protected UI behavior.
- If you add a new runtime file, include it in [Grouper.toc](Grouper.toc).
- Player-facing packages should only include files the game client actually needs.

## Pull Requests

- Use conventional commit titles such as `feat(...)`, `fix(...)`, `docs(...)`, or `ci(...)`.
- Include a short summary of what changed and how you verified it.
- If the change affects game UI, include screenshots or a brief description of the visible behavior.
- Add the `build` label when you want the PR package workflow to post a downloadable addon zip artifact on the PR.
- Keep PRs scoped to one logical change when possible.

## Releases

- Release-specific steps are documented in [RELEASING.md](RELEASING.md).
- Version bumps should update the addon version in [Grouper.toc](Grouper.toc), [Grouper.lua](Grouper.lua), and any matching references in [README.md](README.md) or [CHANGELOG.md](CHANGELOG.md).
- Packaging changes should continue to work with both the PR artifact workflow and the GitHub/CurseForge release workflow.

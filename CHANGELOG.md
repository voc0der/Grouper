# Changelog

All notable changes to Grouper will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.62] - 2026-05-27

### Fixed
- Karazhan Smart Advertiser off-tank asks now stay broad so prot Warriors and bears are both valid second tanks.
- Karazhan fill simulations now include a prot Warrior off-tank regression path instead of always filling the second tank as a bear.

## [1.0.61] - 2026-05-27

### Fixed
- Smart Advertiser fill simulations now preserve configured tank and healer targets for 10-player and 40-player raids instead of letting DPS fill reserved role slots.
- Smart Organize planning now uses 10-player and 40-player simulation scenarios, with clearer two-group labels for 10-player raids.

## [1.0.60] - 2026-05-26

### Changed
- Fill simulations now top up and reorder sample scenarios for recruitment order so tank, healer, caster, and melee shortages can surface instead of inheriting tank-first optimizer fixtures.

## [1.0.59] - 2026-05-26

### Changed
- Smart Advertiser now combines healer or tank shortages with caster/melee DPS steering instead of letting the DPS balance ask hide missing roles.

## [1.0.58] - 2026-05-26

### Changed
- Smart Advertiser now says `need caster dps` or `need melee dps` directly instead of adding priority wording to lopsided DPS fill messages.

## [1.0.57] - 2026-05-26

### Changed
- Smart Advertiser now keeps broad fill messages but adds caster or melee DPS priority when the partial raid composition is clearly lopsided.

## [1.0.56] - 2026-05-26

### Changed
- Smart Advertiser messages now use raid-lead phrasing with `LFM` first, HR next to the raid name, custom text last, broad early asks, and specific late asks only when the missing slot is clear.

## [1.0.55] - 2026-05-26

### Added
- Smart Organize planning mode now includes 2x, 4x, and 8x fill simulations that show Smart Advertiser messages as simulated raiders join, then end on the scored comp preview.

## [1.0.54] - 2026-05-26

### Added
- TBC raid Smart Mode for recruitment ads, with On (ask), Off, and On (guess all specs) settings, spec-aware roster prompts, and organizer-scored class/spec suggestions.

## [1.0.53] - 2026-05-26

### Changed
- Added a shaman-heavy Smart Organize planning simulation so New Sim can show four Shamans, including two Enhancement Shamans.

## [1.0.52] - 2026-05-26

### Changed
- Improved Smart Organize planning scores for partial 25-player raids so prot paladin tanks can take the caster-support threat slot, rogues get Windfury threat support, and healers overflow cleanly into the healer group.

## [1.0.51] - 2026-05-26

### Changed
- Reissued the Smart Organize planning-mode update as a fresh CurseForge package so non-raid clicks open the simulated planning preview.
- Hardened release packaging so the packager is fetched during the workflow and release uploads use the configured release token.

## [1.0.50] - 2026-05-26

### Added
- Smart Organize planning mode for non-raid use, with simulated 20-player and 25-player rosters plus a colored fake raid-frame preview.

### Fixed
- Covered partial 25-player planning so caster groups stay staged even when key support, such as an Elemental Shaman, is still missing.

## [1.0.49] - 2026-05-26

### Fixed
- Cleaned up the main configuration UI layout so interval controls, version checking, and bottom action buttons no longer overlap.

## [1.0.48] - 2026-05-26

### Added
- Smart Organize raid optimizer with role/spec prompts, guessed-spec fallback, scored party synergy, preview explanations, warnings, and leader/assistant-gated apply flow.
- TBC party-placement scoring for threat, physical DPS, caster pump, shadow-priest mana, and healer/overflow raid groups.
- Local Lua tests for Smart Organize scoring and ambiguity handling.
- Runtime-only packaging harness with PR addon artifact workflows and release package verification.
- `CONTRIBUTING.md` development guide.

### Changed
- Release documentation now matches the automated tag/package workflow used by sibling addon repos.

## [1.0.47] - 2026-05-17

### Changed
- Bumped release metadata for the multi-expansion TOC target, including TBC Anniversary `20505`.

### Added
- Boss/dungeon selection persistence - UI now remembers your last selected boss/dungeon
- Layer tracking for world boss kills
  - Integrates with Nova World Buffs to detect current layer
  - Tracks multiple kills per boss with layer information
  - UI shows up to 3 recent kills with layer numbers (e.g., "2d 5h ago L1, 1d 3h ago L2")
  - Backwards compatible with old kill tracking format
- `/grouper about` command to display addon and author information
- Draggable spam buttons with saved positions
  - LFG, Trade, and Stop Recruiting buttons can now be repositioned
  - Button positions are saved and restored between sessions
  - Buttons default to center screen on first use
- Automatic Group Finder (LFG) integration for Anniversary/Season of Discovery
  - Automatically creates and updates Group Finder listing when recruiting
  - Listing updates in real-time as group fills
  - Automatically removed when stopping recruitment
- MIT License for open source distribution
- Stop Recruiting button above Trade/LFG buttons for easy access to stop recruiting
- Faction-based class filtering (Paladins excluded from Horde, Shamans excluded from Alliance for pre-TBC)
- Auto-save on text change for interval inputs in UI
- User feedback messages when intervals are updated
- Four preview message examples including sub-20% case
- CHANGELOG.md for tracking version history
- Release documentation and templates
- Boss kill tracking feature for World Bosses
  - Displays time since last kill (e.g., "Killed 16 days ago") on right side of UI
  - "Mark as Killed" button to manually record boss kills (World Bosses only)
  - Helps remember world boss respawn timers
- Instance lockout tracking for raids and dungeons
  - Shows remaining lockout time (e.g., "Locked out - 2d 14h remaining")
  - Automatically detects if you're saved to an instance
  - Displays "Not saved" if no active lockout

### Changed
- Default spam intervals reduced from 300 to 60 seconds for Trade and LFG channels
- Player count now hidden in messages when group is under 20% filled (e.g., "LFM Azuregos - Need all")
- Removed redundant "/grouper off" message when raid is full (Stop button is now visible)
- Minimap icon changed from dragon head to fish (Raw Mightfish) to better represent "Grouper"
- `/grouper` now opens the UI by default (previously showed help)
- `/grouper help` now shows help text (previously was `/grouper ui` for UI)
- `/grouper ui` still works for backward compatibility

### Fixed
- Boss/dungeon dropdown now properly maintains selection state (fixes blank/greyed out dropdown issue)
- Interval validation now properly accepts values as you type
- Cooldown changes are now applied immediately and saved correctly
- Stop Recruiting button crash when GetLootMethod API is unavailable (added safety check)
- Global variable shadowing issue with config frame stop button (renamed to configStopButton)
- GetBossConfig now safely handles nil boss names to prevent errors
- Group Finder listing now only created on user-initiated actions (fixes "protected function" error)

## [1.0.46] - 2026-01-14

### Fixed
- Fixed CreateFontString error in version check UI tooltip (line 1954)

## [1.0.45] - 2026-01-13

### Added
- Guild version checking system
  - Automatically broadcasts addon version to guild members on login
  - Alerts when a guild member has a newer version available
  - Alert shows once per login session (non-intrusive)
  - Configurable toggle in addon settings to enable/disable feature
  - Uses WoW's addon message system for cross-player communication

## [1.0.44] - 2026-01-13

### Fixed
- Vault of Archavon classification in WOTLK - changed from World Boss to proper 10-man and 25-man raid entries
- Removed Wintergrasp from world boss zones (WOTLK has no outdoor world bosses)

## [1.0.43] - 2026-01-13

### Added
- Zul'Aman to TBC boss list (10-man raid)

## [1.0.12] - Previous Release

### Added
- Preview Messages button to UI
- Minimap button for quick access
- Full configuration GUI accessible via `/grouper ui`
- Support for 40+ dungeons and raids
- Smart messaging based on raid composition
- Separate timers for Trade and LFG channels

### Features
- Automatic raid composition scanning with role detection
- Configurable boss settings (tanks, healers, HR items)
- 60% threshold for detailed recruitment messages
- Master loot warning when stopping recruitment
- Channel spam buttons for easy posting

[Unreleased]: https://github.com/voc0der/Grouper/compare/v1.0.62...HEAD
[1.0.62]: https://github.com/voc0der/Grouper/compare/v1.0.61...v1.0.62
[1.0.61]: https://github.com/voc0der/Grouper/compare/v1.0.60...v1.0.61
[1.0.54]: https://github.com/voc0der/Grouper/compare/v1.0.53...v1.0.54
[1.0.53]: https://github.com/voc0der/Grouper/compare/v1.0.52...v1.0.53
[1.0.52]: https://github.com/voc0der/Grouper/compare/v1.0.51...v1.0.52
[1.0.51]: https://github.com/voc0der/Grouper/compare/v1.0.50...v1.0.51
[1.0.50]: https://github.com/voc0der/Grouper/compare/v1.0.49...v1.0.50
[1.0.49]: https://github.com/voc0der/Grouper/compare/v1.0.48...v1.0.49
[1.0.48]: https://github.com/voc0der/Grouper/compare/v1.0.47...v1.0.48
[1.0.47]: https://github.com/voc0der/Grouper/compare/v1.0.46...v1.0.47
[1.0.46]: https://github.com/voc0der/Grouper/compare/v1.0.45...v1.0.46
[1.0.45]: https://github.com/voc0der/Grouper/compare/v1.0.44...v1.0.45
[1.0.44]: https://github.com/voc0der/Grouper/compare/v1.0.43...v1.0.44
[1.0.43]: https://github.com/voc0der/Grouper/compare/v1.0.12...v1.0.43
[1.0.12]: https://github.com/voc0der/Grouper/releases/tag/v1.0.12

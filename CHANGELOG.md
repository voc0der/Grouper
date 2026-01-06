# Changelog

All notable changes to Grouper will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
- Interval validation now properly accepts values as you type
- Cooldown changes are now applied immediately and saved correctly
- Stop Recruiting button crash when GetLootMethod API is unavailable (added safety check)
- Global variable shadowing issue with config frame stop button (renamed to configStopButton)
- GetBossConfig now safely handles nil boss names to prevent errors
- Group Finder listing now only created on user-initiated actions (fixes "protected function" error)

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

[Unreleased]: https://github.com/voc0der/Grouper/compare/v1.0.12...HEAD
[1.0.12]: https://github.com/voc0der/Grouper/releases/tag/v1.0.12

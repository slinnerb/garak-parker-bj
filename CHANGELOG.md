# Changelog

All notable changes to this game are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com); versions follow
[Semantic Versioning](https://semver.org).

This file is the single source of truth for release notes: the release script
copies the matching version's section into its GitHub release, and the game reads
this file to show "what's new" and past builds when you click the version number.

## [Unreleased]

Nothing yet — this is where the next build's changes will be listed.

## [0.1.0] - 2026-07-15

The first playable build: a vertical slice of the item → deck → combat loop on
the Lovecraftian Coast, plus the full update system.

### Added
- Turn-based combat you can play on screen: draw a hand, play cards, read each
  enemy's telegraphed intent, and win or lose.
- Your gear is your deck — attune the items you carry, and those items generate
  your combat cards. An attunement screen lets you choose your loadout and see
  the deck update as you do.
- The Lovecraftian Coast: a starting set of items, cards, status effects, and
  enemies (three creatures, an elite, and a boss).
- In-game version history: click the version number to see what changed in each
  build and check for updates.
- Automatic update checks on launch, with a one-click "Update & Relaunch".

### Changed
- "New Life" now opens the attunement screen, then a demo fight, as a first
  taste of the item → deck → combat loop.

### Fixed
- Fortified now actually grants block on your turn (it previously wore off before
  it could take effect).
- A fight can no longer start with an empty deck.

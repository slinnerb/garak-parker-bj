# Changelog

All notable changes to this game are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com); versions follow
[Semantic Versioning](https://semver.org).

This file is the single source of truth for release notes: the release script
copies the matching version's section into its GitHub release, and the game reads
this file to show "what's new" and past builds when you click the version number.

## [Unreleased]

Nothing yet — this is where the next build's changes will be listed.

## [0.2.0] - 2026-07-15

The whole loop is playable now: live a life, die, remember, reincarnate stronger.
This is the build the older versions were missing — "New Life" finally leads
somewhere.

### Added
- **A full life, start to finish.** New Life drops you onto a branching map of
  the Lovecraftian Coast — pick your path node to node toward the light at the
  end. (This is the screen the old build couldn't reach — the grey one.)
- **Fights are part of a run.** Your HP carries between battles, the enemy you
  face depends on the node you stepped into, and the final node is a boss.
- **Death is the point.** Fall in a run and you reach the **Moment of Recall**:
  a report of how this life ended, the Remembrance your soul keeps, and a choice
  of adaptation shaped by *how* you died. Choose what to carry, then
  **Reincarnate** into a new life that is measurably stronger.
- **The soul remembers between lives.** Death count, Remembrance, and the
  universes you've lived persist on a permanent profile; the second death
  awakens the Memory Tattoo system (arriving next).
- **A living map:** rest, shrines, item-searches, treasure, merchants, and
  events appear along the way, each doing something distinct when you arrive.

### Changed
- Each universe's own map settings (length, branchiness, guaranteed stops) now
  actually shape its map instead of being ignored.

### Fixed
- Every run is guaranteed at least one place to find an item, on any map size —
  an unlucky layout could previously leave you with none.

## [0.1.2] - 2026-07-15

### Fixed
- The auto-updater could get stuck offering the same update forever. The cause
  was in packaging, not the updater: a release could ship the previous build's
  binary under the new version tag. Releases now confirm the built game reports
  the correct version before publishing.
- Update notes no longer show garbled characters, and the in-game version
  history now appears in the build instead of being blank.

## [0.1.1] - 2026-07-15

### Changed
- A verification build to exercise the in-game auto-updater end to end
  (check on launch → download → self-replace → relaunch). No gameplay changes —
  if your v0.1.0 build updated itself to this one, the update system works.

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

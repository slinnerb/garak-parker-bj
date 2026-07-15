extends TestCase
## Tests for the CHANGELOG.md parser that powers the in-game version history.
## Parses text directly (no file) so it's isolated and deterministic.

const SAMPLE := """# Changelog

Some preamble that must be ignored.

## [Unreleased]

### Added
- A brand new thing.

## [0.2.0] - 2026-08-01

### Added
- Combat prototype.
- Second combat line.

### Fixed
- A nasty bug.

## [0.1.0] - 2026-07-12

### Added
- The foundation.
"""

func test_parses_all_versions_in_order() -> void:
	var entries := Changelog.parse(SAMPLE)
	assert_eq(entries.size(), 3, "three version headers parsed")
	assert_eq(entries[0]["version"], "Unreleased", "first entry is Unreleased")
	assert_eq(entries[1]["version"], "0.2.0", "then 0.2.0")
	assert_eq(entries[2]["version"], "0.1.0", "then 0.1.0")

func test_parses_dates_and_unreleased_flag() -> void:
	var entries := Changelog.parse(SAMPLE)
	assert_true(entries[0]["is_unreleased"], "Unreleased flagged")
	assert_false(entries[1]["is_unreleased"], "a dated version is not unreleased")
	assert_eq(entries[1]["date"], "2026-08-01", "date parsed from the header")

func test_parses_sections_and_items() -> void:
	var entries := Changelog.parse(SAMPLE)
	var v020: Dictionary = entries[1]
	var sections: Array = v020["sections"]
	assert_eq(sections.size(), 2, "0.2.0 has Added and Fixed")
	assert_eq(sections[0]["heading"], "Added", "first section heading")
	assert_eq((sections[0]["items"] as Array).size(), 2, "two Added bullets")
	assert_eq(sections[0]["items"][0], "Combat prototype.", "bullet text stripped of '- '")
	assert_eq(sections[1]["heading"], "Fixed", "second section is Fixed")

func test_preamble_bullets_are_ignored() -> void:
	# A '- ' line before any '## ' header must not attach to a version.
	var entries := Changelog.parse("preamble\n- stray bullet\n## [1.0.0]\n### Added\n- real\n")
	assert_eq(entries.size(), 1, "only the real version")
	assert_eq(entries[0]["sections"][0]["items"], ["real"], "stray preamble bullet dropped")

func test_latest_and_for_version_lookup() -> void:
	var entries := Changelog.parse(SAMPLE)
	assert_eq(Changelog.latest(entries)["version"], "Unreleased", "latest is the top entry")
	assert_eq(Changelog.for_version(entries, "0.2.0")["date"], "2026-08-01", "found by exact version")
	assert_eq(Changelog.for_version(entries, "v0.1.0")["version"], "0.1.0", "leading 'v' ignored")
	assert_true(Changelog.for_version(entries, "9.9.9").is_empty(), "missing version -> empty")

func test_bundled_changelog_loads_and_parses() -> void:
	# The real res://CHANGELOG.md must exist and parse to at least one entry, so
	# the shipped history panel is never blank.
	var entries := Changelog.load_entries()
	assert_gt(entries.size(), 0, "the bundled changelog parses to at least one version")

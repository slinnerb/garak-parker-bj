class_name Changelog
extends RefCounted
## Parses CHANGELOG.md into structured entries the game can display.
##
## The file is Keep-a-Changelog format: `## [version] - date` headers, each with
## `### Added/Changed/Removed/Fixed` subsections of `- ` bullet lines. This turns
## that text into data so the version-history panel can render it, and so the
## release script and the game agree on one source of truth. Bundled with the
## build (res://CHANGELOG.md), so history works offline; the updater only reaches
## the network to find something *newer* than the running build.
##
## A parsed entry:
##   { "version": "0.2.0", "date": "2026-08-01", "is_unreleased": false,
##     "sections": [ {"heading": "Added", "items": ["..."]}, ... ] }

const CHANGELOG_PATH := "res://CHANGELOG.md"


## Loads and parses the bundled changelog. Returns [] if it can't be read.
static func load_entries() -> Array:
	if not FileAccess.file_exists(CHANGELOG_PATH):
		return []
	var file := FileAccess.open(CHANGELOG_PATH, FileAccess.READ)
	if file == null:
		return []
	return parse(file.get_as_text())


## Parses changelog text. Public + static so it's unit-testable without a file.
## Entries are returned in file order (newest first, by convention).
static func parse(text: String) -> Array:
	var entries: Array = []
	var current: Dictionary = {}
	var current_section: Dictionary = {}

	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.begins_with("## "):
			# New version header: "## [1.2.0] - 2026-08-01" or "## [Unreleased]".
			current = _parse_version_header(line)
			current_section = {}
			entries.append(current)
		elif line.begins_with("### ") and not current.is_empty():
			# New subsection: "### Added".
			current_section = {"heading": line.substr(4).strip_edges(), "items": []}
			(current["sections"] as Array).append(current_section)
		elif line.begins_with("- ") and not current_section.is_empty():
			(current_section["items"] as Array).append(line.substr(2).strip_edges())

	return entries


## The most recent entry (the top version), or {} if none.
static func latest(entries: Array) -> Dictionary:
	return entries[0] if not entries.is_empty() else {}


## Finds the entry whose version matches (ignoring a leading "v"), or {}.
static func for_version(entries: Array, version: String) -> Dictionary:
	var wanted := version.lstrip("v")
	for entry in entries:
		if str(entry.get("version", "")).lstrip("v") == wanted:
			return entry
	return {}


static func _parse_version_header(line: String) -> Dictionary:
	# Strip "## ", then split an optional "- date" suffix.
	var rest := line.substr(3).strip_edges()
	var version := rest
	var date := ""
	var dash := rest.find(" - ")
	if dash != -1:
		version = rest.substr(0, dash).strip_edges()
		date = rest.substr(dash + 3).strip_edges()
	version = version.trim_prefix("[").trim_suffix("]")
	return {
		"version": version,
		"date": date,
		"is_unreleased": version.to_lower() == "unreleased",
		"sections": [],
	}

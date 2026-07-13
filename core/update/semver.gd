class_name SemVer
extends RefCounted
## Minimal semantic-version comparison used by the updater.
##
## Handles "MAJOR.MINOR.PATCH", tolerates a leading "v" (GitHub tags are usually
## "v0.2.0"), and ignores pre-release/build metadata for ordering purposes
## (e.g. "1.2.0-beta" compares as "1.2.0"). Pure and static so it is trivially
## unit-testable without the engine (see tests/unit/test_semver.gd).

## Parses a version string into [major, minor, patch]. Missing / non-numeric
## parts become 0, so malformed input degrades gracefully rather than crashing.
static func parse(s: String) -> Array:
	var t := s.strip_edges()
	if t.begins_with("v") or t.begins_with("V"):
		t = t.substr(1)
	# Drop pre-release ("-...") and build ("+...") metadata.
	var dash := t.find("-")
	if dash != -1:
		t = t.substr(0, dash)
	var plus := t.find("+")
	if plus != -1:
		t = t.substr(0, plus)
	var parts := t.split(".")
	var out := [0, 0, 0]
	for i in range(min(3, parts.size())):
		out[i] = _to_int(parts[i])
	return out


## Returns -1 if a < b, 0 if equal, 1 if a > b (by [major, minor, patch]).
static func compare(a: String, b: String) -> int:
	var pa := parse(a)
	var pb := parse(b)
	for i in range(3):
		if pa[i] < pb[i]:
			return -1
		if pa[i] > pb[i]:
			return 1
	return 0


## True when `candidate` is strictly newer than `current`.
static func is_newer(candidate: String, current: String) -> bool:
	return compare(candidate, current) > 0


static func _to_int(part: String) -> int:
	var digits := ""
	for c in part:
		if c >= "0" and c <= "9":
			digits += c
		else:
			break
	return int(digits) if not digits.is_empty() else 0

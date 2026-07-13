class_name GameVersion
extends RefCounted
## Single source of truth for the game version.
##
## The canonical value lives in project.godot ([application] config/version).
## Everything (update checks, UI, save headers) reads it from here so there is
## exactly one place to bump. The release pipeline (tools/release/release.ps1)
## edits project.godot, which flows through this function automatically.

## Returns the current game version string, e.g. "0.1.0".
static func current() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))

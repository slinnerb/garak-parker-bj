extends TestCase
## Guards the single-source-of-truth version wiring.

func test_version_is_present_and_valid() -> void:
	var v := GameVersion.current()
	assert_ne(v, "", "version string must not be empty")
	var parts := SemVer.parse(v)
	assert_eq(parts.size(), 3, "version parses to major.minor.patch")

func test_version_matches_project_setting() -> void:
	# GameVersion reads ProjectSettings, so these are the same by construction;
	# this test fails loudly if that wiring is ever changed to hard-code a value.
	var from_helper := GameVersion.current()
	var from_settings := str(ProjectSettings.get_setting("application/config/version", ""))
	assert_eq(from_helper, from_settings, "GameVersion must reflect project.godot")

extends TestCase
## Tests for SemVer version comparison (drives the update checker).

func test_parse_plain() -> void:
	assert_eq(SemVer.parse("1.2.3"), [1, 2, 3])

func test_parse_with_v_prefix() -> void:
	assert_eq(SemVer.parse("v0.4.10"), [0, 4, 10])
	assert_eq(SemVer.parse("V2.0.0"), [2, 0, 0])

func test_parse_missing_parts() -> void:
	assert_eq(SemVer.parse("1"), [1, 0, 0])
	assert_eq(SemVer.parse("1.5"), [1, 5, 0])

func test_parse_prerelease_and_build_ignored() -> void:
	assert_eq(SemVer.parse("1.2.0-beta"), [1, 2, 0])
	assert_eq(SemVer.parse("1.2.0+build7"), [1, 2, 0])
	assert_eq(SemVer.parse("v1.2.3-rc.1+meta"), [1, 2, 3])

func test_parse_garbage_is_safe() -> void:
	assert_eq(SemVer.parse("not-a-version"), [0, 0, 0])
	assert_eq(SemVer.parse(""), [0, 0, 0])

func test_compare_ordering() -> void:
	assert_eq(SemVer.compare("1.0.0", "1.0.0"), 0)
	assert_eq(SemVer.compare("1.0.0", "1.0.1"), -1)
	assert_eq(SemVer.compare("1.1.0", "1.0.9"), 1)
	assert_eq(SemVer.compare("2.0.0", "1.9.9"), 1)

func test_is_newer() -> void:
	assert_true(SemVer.is_newer("0.2.0", "0.1.0"), "0.2.0 should be newer than 0.1.0")
	assert_true(SemVer.is_newer("v1.0.0", "0.9.5"), "handles v prefix")
	assert_false(SemVer.is_newer("0.1.0", "0.1.0"), "equal is not newer")
	assert_false(SemVer.is_newer("0.1.0", "0.2.0"), "older is not newer")
	# The exact scenario the game runs: same version installed and released.
	assert_false(SemVer.is_newer("v0.1.0", "0.1.0"), "tag vs plain, equal")

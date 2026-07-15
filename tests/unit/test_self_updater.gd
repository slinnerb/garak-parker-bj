extends TestCase
## Tests the pure part of the self-update mechanism: the helper batch script that
## swaps the build and relaunches. The download/extract/launch steps need a real
## packaged build to exercise and aren't unit-tested here.

func test_helper_bat_contains_full_swap_sequence() -> void:
	var bat := SelfUpdater.build_helper_bat("C:/games/gpbj/Game.exe", "C:/games/gpbj/Game.exe.new")
	assert_true(bat.contains("Game.exe"), "names the old exe")
	assert_true(bat.contains("Game.exe.new"), "names the downloaded new exe")
	assert_true(bat.contains(":waitloop"), "waits for the game to exit")
	assert_true(bat.contains("move /y"), "swaps the new build in")
	assert_true(bat.contains("start \"\""), "relaunches the game")
	assert_true(bat.contains("del \"%~f0\""), "the helper deletes itself")

func test_helper_bat_uses_windows_paths() -> void:
	var bat := SelfUpdater.build_helper_bat("C:/a/b.exe", "C:/a/b.exe.new")
	assert_true(bat.contains("C:\\a\\b.exe"), "forward slashes converted to backslashes for cmd.exe")
	assert_false(bat.contains("C:/a/b.exe"), "no forward-slash paths remain")

func test_helper_bat_double_percent_not_emitted() -> void:
	# Guards the earlier bug where %~f0 was written as %%~f0 (which cmd would not
	# expand to the script path).
	var bat := SelfUpdater.build_helper_bat("C:/x/y.exe", "C:/x/y.exe.new")
	assert_false(bat.contains("%%~f0"), "self-delete uses a single %, not %%")

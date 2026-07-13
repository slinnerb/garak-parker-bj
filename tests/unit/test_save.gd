extends TestCase
## Save system tests. Uses the "run" domain (which is meant to be ephemeral) so
## the developer's real profile is never touched, and cleans up after itself.

const SAVE_DIR := "user://saves"

func _wipe_run_files() -> void:
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return
	for name in ["run.json", "run.json.bak", "run.json.tmp", "run.json.corrupt"]:
		if dir.file_exists(name):
			dir.remove(name)

func test_run_round_trip() -> void:
	_wipe_run_files()
	var payload := {"universe": "lovecraft_coast", "seed": 424242, "node": 5}
	assert_true(SaveManager.set_data("run", payload), "save should succeed")
	# Read straight from disk (bypassing the in-memory cache).
	var reloaded := SaveManager.load_domain("run")
	assert_eq(str(reloaded.get("universe")), "lovecraft_coast")
	assert_eq(int(reloaded.get("seed")), 424242)
	assert_eq(int(reloaded.get("node")), 5)
	_wipe_run_files()

func test_backup_created_on_second_save() -> void:
	_wipe_run_files()
	SaveManager.set_data("run", {"n": 1})
	SaveManager.set_data("run", {"n": 2})  # should back up the first
	var dir := DirAccess.open(SAVE_DIR)
	assert_true(dir.file_exists("run.json.bak"), "a .bak of the prior save should exist")
	_wipe_run_files()

func test_corrupt_file_recovers_to_default_and_quarantines() -> void:
	_wipe_run_files()
	# Write junk where a save should be.
	var f := FileAccess.open("%s/run.json" % SAVE_DIR, FileAccess.WRITE)
	f.store_string("{ this is not valid json ]")
	f.close()
	var data := SaveManager.load_domain("run")
	assert_eq(data, {}, "corrupt run save falls back to default (empty)")
	var dir := DirAccess.open(SAVE_DIR)
	assert_true(dir.file_exists("run.json.corrupt"), "bad file is quarantined, not deleted")
	_wipe_run_files()

func test_profile_defaults_shape() -> void:
	var d := SaveManager.default_data("profile")
	assert_has(d, "soul_level")
	assert_has(d, "life_count")
	assert_has(d, "death_count")
	assert_has(d, "tattoo_system_unlocked")
	assert_eq(d["unlocked_universes"], ["lovecraft_coast"], "starts with the first universe unlocked")

func test_merge_defaults_fills_and_preserves() -> void:
	var defaults := {"a": 1, "b": 2, "nested": {"x": 10, "y": 20}}
	var partial := {"a": 99, "nested": {"x": 111}}
	var merged: Dictionary = SaveManager._merge_defaults(defaults, partial)
	assert_eq(int(merged["a"]), 99, "existing values are preserved")
	assert_eq(int(merged["b"]), 2, "missing top-level keys are filled")
	assert_eq(int(merged["nested"]["x"]), 111, "existing nested values preserved")
	assert_eq(int(merged["nested"]["y"]), 20, "missing nested keys filled")

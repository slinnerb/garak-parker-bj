extends SceneTree
## Headless test runner.
##
## Run with:
##   Godot_v4.7-stable_win64.exe --headless --path . --script res://tests/run_all.gd
##
## Discovers every res://tests/unit/*.gd, instantiates each (they extend
## TestCase), runs its `test_*` methods, and reports. Exit code is 0 when all
## pass and 1 otherwise, so CI / scripts can gate on it.

const UNIT_DIR := "res://tests/unit"


func _initialize() -> void:
	print("")
	print("==================== TEST RUN ====================")
	var total := 0
	var passed := 0
	var failed := 0
	var failures: Array[String] = []

	for path in _discover_test_scripts():
		var script: GDScript = load(path)
		if script == null:
			failures.append("%s: could not load script" % path)
			failed += 1
			continue
		var instance = script.new()
		if not (instance is TestCase):
			print("  SKIP %s (not a TestCase)" % path)
			continue

		var suite := path.get_file()
		for method in instance.get_method_list():
			var name: String = method.name
			if not name.begins_with("test_"):
				continue
			total += 1
			instance.failures.clear()
			instance.call(name)
			if instance.failures.is_empty():
				passed += 1
				print("  PASS %s :: %s" % [suite, name])
			else:
				failed += 1
				for f in instance.failures:
					failures.append("%s :: %s -> %s" % [suite, name, f])
				print("  FAIL %s :: %s" % [suite, name])

	print("--------------------------------------------------")
	if failed > 0:
		print("FAILURES:")
		for f in failures:
			print("  - %s" % f)
	print("RESULT: %d passed, %d failed, %d total" % [passed, failed, total])
	print("==================================================")
	print("")

	quit(1 if failed > 0 else 0)


func _discover_test_scripts() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(UNIT_DIR)
	if dir == null:
		push_error("Could not open %s" % UNIT_DIR)
		return out
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".gd"):
			out.append("%s/%s" % [UNIT_DIR, file])
		file = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out

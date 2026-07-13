extends SceneTree
## Dev-only: run a single update check headlessly and print the result, so the
## update pipeline can be verified without the GUI.
##
##   Godot ... --headless --path . --script res://tools/debug/check_updates_once.gd
##
## NOTE: autoload singletons (EventBus, Updater) are not available as global
## identifiers inside the entry --script at compile time, so we resolve them
## from /root at runtime after they've entered the tree.

func _initialize() -> void:
	# Let the autoloads run their _ready() (creates Updater's HTTPRequest child).
	await process_frame
	await process_frame

	var bus := root.get_node_or_null("/root/EventBus")
	var updater := root.get_node_or_null("/root/Updater")
	if bus == null or updater == null:
		print("UPDATE_RESULT status=error info={\"reason\":\"autoloads missing\"}")
		quit(1)
		return

	var done := {"v": false}
	bus.update_check_completed.connect(func(status: String, info: Dictionary) -> void:
		print("UPDATE_RESULT status=%s info=%s" % [status, JSON.stringify(info)])
		done["v"] = true
	)
	updater.check_for_updates()

	var frames := 0
	while not done["v"] and frames < 900:
		await process_frame
		frames += 1
	if not done["v"]:
		print("UPDATE_RESULT status=timeout")
	quit(0)

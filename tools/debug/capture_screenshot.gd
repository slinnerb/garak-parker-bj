extends SceneTree
## Dev-only: render a scene to a PNG for visual verification / bug reports.
##
##   Godot ... --path . --script res://tools/debug/capture_screenshot.gd \
##       -- --scene=res://scenes/menus/main_menu.tscn --out=C:/tmp/menu.png
##
## Runs windowed (NOT --headless — headless has no framebuffer to capture).
## Defaults to the main menu -> user://capture.png.

func _initialize() -> void:
	var scene_path := "res://scenes/menus/main_menu.tscn"
	var out_path := "user://capture.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene_path = a.trim_prefix("--scene=")
		elif a.begins_with("--out="):
			out_path = a.trim_prefix("--out=")

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("capture_screenshot: could not load %s" % scene_path)
		quit(1)
		return
	root.add_child(packed.instantiate())

	# Let the UI lay out and paint for a few frames before grabbing the frame.
	for _i in 12:
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	var err := img.save_png(out_path)
	if err != OK:
		push_error("capture_screenshot: save_png failed (err %d) -> %s" % [err, out_path])
		quit(1)
		return
	print("Saved screenshot -> %s" % ProjectSettings.globalize_path(out_path))
	quit(0)

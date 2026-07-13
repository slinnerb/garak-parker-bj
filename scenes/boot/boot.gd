extends Control
## Boot screen. Shows a brief splash while GameBootstrap runs the non-visual
## startup sequence, then hands off to the main menu.

@onready var _status: Label = $Center/VBox/StatusLabel


func _ready() -> void:
	# Wait one frame so autoloads have finished their own _ready() and the
	# splash paints before we do any work.
	await get_tree().process_frame

	var ok := GameBootstrap.boot()
	if not ok:
		_status.text = "Started with content warnings — see log."
	else:
		_status.text = "Ready."

	# Tiny splash hold; keeps the transition from feeling like a flicker.
	await get_tree().create_timer(0.4).timeout
	SceneFlow.goto_main_menu()

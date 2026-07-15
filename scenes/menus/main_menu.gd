extends Control
## Main menu. The foundation's playable surface: it proves the shell boots, the
## version is visible, and the Check-for-Updates loop works end to end.
##
## Gameplay buttons (New Life / Continue / Settings) are intentionally inert
## until their systems land in later phases — they are present so the layout and
## navigation are real, but they don't pretend to do something they can't.

@onready var _version_label: Label = %VersionLabel
@onready var _status_label: Label = %StatusLabel
@onready var _new_life_button: Button = %NewLifeButton
@onready var _continue_button: Button = %ContinueButton
@onready var _update_button: Button = %UpdateButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton

var _updates_panel: UpdatesPanel


func _ready() -> void:
	_version_label.text = "v%s" % GameVersion.current()
	_set_status("")

	# The version number is a doorway to updates & version history.
	_version_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_version_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_version_label.tooltip_text = "Updates & version history"
	_version_label.gui_input.connect(_on_version_label_input)

	# The updates panel owns all update UI (check, install, history) and connects
	# to the Updater itself, so an auto-check that finds an update auto-opens it.
	_updates_panel = UpdatesPanel.new()
	add_child(_updates_panel)

	# Buttons that work today.
	_update_button.pressed.connect(_on_update_pressed)
	_quit_button.pressed.connect(func() -> void: SceneFlow.quit_game())

	# New Life currently opens the attunement screen (pick your loadout), then a
	# demo fight — a real preview of the item->deck->combat spine until the
	# between-life hub and run map exist (later phases).
	_new_life_button.pressed.connect(_on_new_life_pressed)
	_new_life_button.tooltip_text = "Choose a loadout, then fight on the Lovecraftian coast (full run flow comes later)."

	_continue_button.disabled = not SaveManager.has_active_run()
	_continue_button.tooltip_text = "No life in progress." if _continue_button.disabled else "Resume your current life."
	_continue_button.pressed.connect(_on_continue_pressed)

	_settings_button.disabled = true
	_settings_button.tooltip_text = "Settings screen coming soon."

	_update_button.grab_focus()

	# Check once on launch. If a newer build exists the panel auto-opens with the
	# changelog and an Update & Relaunch button; if not, nothing interrupts.
	Updater.check_for_updates()


# --- Buttons ---------------------------------------------------------------

func _on_update_pressed() -> void:
	_updates_panel.open_and_check()


func _on_version_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_updates_panel.open()


func _on_new_life_pressed() -> void:
	SceneFlow.goto_attunement()


func _on_continue_pressed() -> void:
	_set_status("Resuming is not available until run scenes exist.")


# --- Helpers ---------------------------------------------------------------

func _set_status(text: String) -> void:
	_status_label.text = text

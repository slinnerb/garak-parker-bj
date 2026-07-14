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
@onready var _update_dialog: AcceptDialog = %UpdateDialog

var _pending_download_url: String = ""


func _ready() -> void:
	_version_label.text = "v%s" % GameVersion.current()
	_set_status("")

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

	# Update dialog: confirming opens the download page.
	_update_dialog.ok_button_text = "Open Download Page"
	_update_dialog.add_cancel_button("Later")
	_update_dialog.confirmed.connect(_on_update_dialog_confirmed)

	# Update service signals. These auto-disconnect when this menu is freed.
	Updater.check_started.connect(_on_check_started)
	Updater.update_available.connect(_on_update_available)
	Updater.up_to_date.connect(_on_up_to_date)
	Updater.check_failed.connect(_on_check_failed)

	_update_button.grab_focus()


# --- Buttons ---------------------------------------------------------------

func _on_update_pressed() -> void:
	Updater.check_for_updates()


func _on_new_life_pressed() -> void:
	SceneFlow.goto_attunement()


func _on_continue_pressed() -> void:
	_set_status("Resuming is not available until run scenes exist.")


# --- Update flow -----------------------------------------------------------

func _on_check_started() -> void:
	_update_button.disabled = true
	_set_status("Checking for updates…")


func _on_update_available(info: Dictionary) -> void:
	_update_button.disabled = false
	_pending_download_url = str(info.get("url", ""))
	var version := str(info.get("version", "?"))
	var current := str(info.get("current", GameVersion.current()))
	var notes := str(info.get("notes", "")).strip_edges()
	if notes.is_empty():
		notes = "A newer version is available."
	_update_dialog.title = "Update available"
	_update_dialog.dialog_text = "You're on v%s.\nVersion %s is available.\n\n%s" % [current, version, notes]
	_update_dialog.popup_centered(Vector2i(520, 300))
	_set_status("Update available: %s" % version)


func _on_up_to_date(current_version: String) -> void:
	_update_button.disabled = false
	_set_status("You're on the latest version (v%s)." % current_version)


func _on_check_failed(reason: String) -> void:
	_update_button.disabled = false
	_set_status(reason)


func _on_update_dialog_confirmed() -> void:
	if not _pending_download_url.is_empty():
		Log.info(Log.Cat.UPDATE, "Opening download page: %s" % _pending_download_url)
		OS.shell_open(_pending_download_url)


# --- Helpers ---------------------------------------------------------------

func _set_status(text: String) -> void:
	_status_label.text = text

class_name UpdatesPanel
extends Control
## The "Updates & Version History" surface (update system).
##
## Opened by clicking the version number. Shows the current build, a Check for
## Updates action, and — when a newer build exists — an Update & Relaunch button
## that downloads and installs it. Below that, the full version history parsed
## from the bundled CHANGELOG.md, so a player can see what each build added,
## changed, or fixed even offline.
##
## Presentation only: it drives the Updater (check / install) and reads the
## Changelog; it holds no update logic itself. Self-connects to Updater signals
## and updates its own UI, so it works whether opened manually or auto-shown when
## a launch-time check finds an update.

var _status_label: Label
var _check_button: Button
var _update_box: PanelContainer
var _update_title: Label
var _update_notes: RichTextLabel
var _update_button: Button
var _progress_bar: ProgressBar
var _progress_label: Label
var _history_list: VBoxContainer
var _current_info: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()
	_populate_history()
	_status_label.text = "You're on v%s." % GameVersion.current()

	Updater.check_started.connect(_on_check_started)
	Updater.update_available.connect(_on_update_available)
	Updater.up_to_date.connect(_on_up_to_date)
	Updater.check_failed.connect(_on_check_failed)
	Updater.install_started.connect(_on_install_started)
	Updater.install_progress.connect(_on_install_progress)
	Updater.install_failed.connect(_on_install_failed)
	Updater.install_unavailable.connect(_on_install_unavailable)


# ---------------------------------------------------------------------------
# Open / close
# ---------------------------------------------------------------------------

func open() -> void:
	visible = true

func open_and_check() -> void:
	open()
	Updater.check_for_updates()

func close() -> void:
	visible = false


# ---------------------------------------------------------------------------
# Updater signal handlers
# ---------------------------------------------------------------------------

func _on_check_started() -> void:
	_check_button.disabled = true
	_status_label.text = "Checking for updates…"

func _on_update_available(info: Dictionary) -> void:
	_current_info = info
	_check_button.disabled = false
	_status_label.text = "An update is available."
	_update_title.text = "Version %s is available — you're on v%s." % [str(info.get("version", "?")), str(info.get("current", GameVersion.current()))]
	var notes := str(info.get("notes", "")).strip_edges()
	_update_notes.text = notes if not notes.is_empty() else "A newer build is available."
	_update_button.text = "Update & Relaunch"
	_update_button.disabled = false
	_update_box.visible = true
	open()

func _on_up_to_date(current_version: String) -> void:
	_check_button.disabled = false
	_update_box.visible = false
	_status_label.text = "You're on the latest version (v%s)." % current_version

func _on_check_failed(reason: String) -> void:
	_check_button.disabled = false
	_status_label.text = reason

func _on_install_started() -> void:
	_update_button.disabled = true
	_update_button.text = "Downloading…"
	_status_label.text = "Downloading the update — the game will relaunch when it's ready."
	_progress_bar.visible = true
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_label.visible = true
	_progress_label.text = "Contacting the server…"

func _on_install_progress(downloaded_bytes: int, total_bytes: int) -> void:
	var mb := downloaded_bytes / 1048576.0
	if total_bytes > 0:
		_progress_bar.max_value = float(total_bytes)
		_progress_bar.value = float(downloaded_bytes)
		_progress_label.text = "Downloading…  %.1f / %.1f MB" % [mb, total_bytes / 1048576.0]
	else:
		# Size unknown — cycle the bar each MB so motion is still visible.
		_progress_bar.max_value = 1.0
		_progress_bar.value = fmod(mb, 1.0)
		_progress_label.text = "Downloading…  %.1f MB" % mb

func _on_install_failed(reason: String) -> void:
	_update_button.disabled = false
	_update_button.text = "Update & Relaunch"
	_status_label.text = "Update failed: %s" % reason
	_progress_bar.visible = false
	_progress_label.visible = false

func _on_install_unavailable(reason: String) -> void:
	# e.g. running in the editor — fall back to the download page.
	_update_button.disabled = false
	_update_button.text = "Open Download Page"
	_status_label.text = reason


# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

func _on_check_pressed() -> void:
	Updater.check_for_updates()

func _on_update_pressed() -> void:
	if _update_button.text == "Open Download Page":
		var url := str(_current_info.get("url", UpdateConfig.releases_page_url()))
		OS.shell_open(url)
		return
	Updater.install_update(_current_info)


# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------

func _populate_history() -> void:
	var entries := Changelog.load_entries()
	if entries.is_empty():
		_history_list.add_child(UiKit.label("No version history available.", 13, UiKit.MUTED))
		return
	for entry in entries:
		_history_list.add_child(_render_entry(entry))


func _render_entry(entry: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var version := str(entry.get("version", "?"))
	var date := str(entry.get("date", ""))
	var heading := version if bool(entry.get("is_unreleased", false)) else "v%s" % version
	if not date.is_empty():
		heading += "  ·  %s" % date
	if version == GameVersion.current():
		heading += "   (this build)"
	box.add_child(UiKit.label(heading, 16, UiKit.AMBER))

	for section in entry.get("sections", []):
		box.add_child(UiKit.label(str(section.get("heading", "")), 12, UiKit.INK))
		for item in section.get("items", []):
			var bullet := UiKit.label("•  %s" % str(item), 13, UiKit.MUTED)
			bullet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(bullet)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	box.add_child(spacer)
	return box


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP  # eat clicks behind the panel
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 580)
	panel.add_theme_stylebox_override("panel", UiKit.stylebox(UiKit.PANEL, UiKit.BORDER, 1, 10))
	center.add_child(panel)

	var pad := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 26)
	panel.add_child(pad)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	pad.add_child(root)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var title := UiKit.label("Updates & Version History", 20, UiKit.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 36)
	close_btn.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(close_btn, UiKit.PANEL, UiKit.BORDER)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	# Status + check
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 12)
	root.add_child(status_row)
	_status_label = UiKit.label("", 14, UiKit.MUTED)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_row.add_child(_status_label)
	_check_button = Button.new()
	_check_button.text = "Check for Updates"
	_check_button.custom_minimum_size = Vector2(170, 40)
	_check_button.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(_check_button, UiKit.PANEL, UiKit.BORDER)
	_check_button.pressed.connect(_on_check_pressed)
	status_row.add_child(_check_button)

	# Update-available box (hidden until there's one)
	_update_box = PanelContainer.new()
	_update_box.visible = false
	_update_box.add_theme_stylebox_override("panel", UiKit.stylebox(Color(0.16, 0.13, 0.08), UiKit.AMBER))
	root.add_child(_update_box)
	var ubox := VBoxContainer.new()
	ubox.add_theme_constant_override("separation", 8)
	_update_box.add_child(ubox)
	_update_title = UiKit.label("", 15, UiKit.INK)
	ubox.add_child(_update_title)
	_update_notes = RichTextLabel.new()
	_update_notes.bbcode_enabled = false
	_update_notes.fit_content = true
	_update_notes.scroll_active = false
	_update_notes.custom_minimum_size = Vector2(0, 40)
	_update_notes.add_theme_color_override("default_color", UiKit.MUTED)
	_update_notes.add_theme_font_size_override("normal_font_size", 13)
	ubox.add_child(_update_notes)
	_update_button = Button.new()
	_update_button.text = "Update & Relaunch"
	_update_button.custom_minimum_size = Vector2(190, 42)
	_update_button.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(_update_button, Color(0.18, 0.14, 0.08), UiKit.AMBER, true)
	_update_button.pressed.connect(_on_update_pressed)
	ubox.add_child(_update_button)

	# Download progress: proof of life while the ~38 MB build streams in.
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 14)
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	_progress_bar.add_theme_stylebox_override("background", UiKit.stylebox(Color(0.10, 0.09, 0.06), UiKit.BORDER, 1, 4))
	_progress_bar.add_theme_stylebox_override("fill", UiKit.stylebox(UiKit.AMBER, UiKit.AMBER, 0, 4))
	ubox.add_child(_progress_bar)
	_progress_label = UiKit.label("", 12, UiKit.MUTED)
	_progress_label.visible = false
	ubox.add_child(_progress_label)

	var rule := HSeparator.new()
	root.add_child(rule)
	root.add_child(UiKit.label("What's changed", 15, UiKit.INK))

	# History (scrollable)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_history_list = VBoxContainer.new()
	_history_list.add_theme_constant_override("separation", 6)
	_history_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_history_list)

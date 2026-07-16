extends Control
## The Moment of Recall (Phase 6b) — the death sequence, and the heart of the
## game: while alive the character forgets; at death, the soul remembers.
##
## Shows the death report, the Remembrance earned, and the adaptations this
## death makes available. Choosing one (or taking nothing) records the death on
## the profile — exactly once — then offers reincarnation into the next life.
## Presentation only: the rules live in DeathReport / SoulProgression / Soul.

var _report: DeathReport
var _recorded := false

var _root_box: VBoxContainer


func _ready() -> void:
	if ContentRegistry.ids_of("adaptation").is_empty():
		ContentLoader.load_all(ContentRegistry)
	_report = RunManager.last_death_report
	_build_frame()
	if _report == null:
		# Reached without a death (direct scene load) — nothing to recall.
		_show_result({}, "The dark holds no memories today.")
		return
	_show_choice()


# ---------------------------------------------------------------------------
# Stage 1 — the recall: report + adaptation choice
# ---------------------------------------------------------------------------

func _show_choice() -> void:
	_clear_box()
	_add_header()

	var eligible := SoulProgression.eligible_adaptations(ContentRegistry, _report, Soul.adaptations())
	if eligible.is_empty():
		_root_box.add_child(UiKit.label("This death teaches no new adaptation — but the soul still keeps its Remembrance.", 14, UiKit.MUTED))
	else:
		_root_box.add_child(UiKit.label("Something in the soul adapts. Choose what this death leaves behind:", 14, UiKit.INK))
		for def in eligible:
			_root_box.add_child(_adaptation_button(def))

	var skip := Button.new()
	skip.text = "Carry nothing forward"
	skip.custom_minimum_size = Vector2(0, 40)
	skip.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(skip, UiKit.PANEL, UiKit.BORDER)
	skip.pressed.connect(func() -> void: _choose(""))
	_root_box.add_child(skip)


func _adaptation_button(def) -> Button:
	var btn := Button.new()
	# Tall enough for name + two description lines + the drawback warning.
	btn.custom_minimum_size = Vector2(0, 104)
	btn.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(btn, UiKit.PANEL_HI, UiKit.AMBER, true)
	btn.pressed.connect(func() -> void: _choose(def.id))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 8
	box.offset_right = -14
	box.offset_bottom = -8
	box.add_theme_constant_override("separation", 3)
	btn.add_child(box)
	box.add_child(UiKit.label(def.display_name, 16, UiKit.AMBER))
	var desc := UiKit.label(def.description, 12, UiKit.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)
	if not def.drawback.is_empty():
		box.add_child(UiKit.label("…but every adaptation costs something.", 11, UiKit.DANGER))
	UiKit.ignore_mouse(box)
	return btn


func _choose(adaptation_id: String) -> void:
	if _recorded:
		return
	_recorded = true
	var outcome := Soul.record_death(_report, adaptation_id)
	var taken := ""
	if not adaptation_id.is_empty():
		var def = ContentRegistry.get_def("adaptation", adaptation_id)
		taken = def.display_name if def != null else adaptation_id
	_show_result(outcome, taken)


# ---------------------------------------------------------------------------
# Stage 2 — the result: what the soul keeps, and reincarnation
# ---------------------------------------------------------------------------

func _show_result(outcome: Dictionary, taken_name: String) -> void:
	_clear_box()
	_add_header()

	if not taken_name.is_empty() and _report != null:
		_root_box.add_child(UiKit.label("The soul keeps: %s" % taken_name, 15, UiKit.AMBER))
	if bool(outcome.get("tattoo_just_unlocked", false)):
		var banner := UiKit.label("✦ Something has marked the soul itself. From the next life onward, Memory Tattoos await. ✦", 14, UiKit.GOOD)
		banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_root_box.add_child(banner)

	_root_box.add_child(UiKit.label("The soul now holds %d Remembrance across %d deaths." % [Soul.remembrance(), Soul.death_count()], 13, UiKit.MUTED))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	_root_box.add_child(spacer)

	var reincarnate := Button.new()
	reincarnate.text = "Reincarnate  ⟶"
	reincarnate.custom_minimum_size = Vector2(0, 48)
	reincarnate.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(reincarnate, Color(0.16, 0.13, 0.08), UiKit.AMBER, true)
	reincarnate.pressed.connect(func() -> void:
		RunManager.begin_new_life(ContentRegistry)
		SceneFlow.goto_map())
	_root_box.add_child(reincarnate)

	var menu := Button.new()
	menu.text = "Rest a while (main menu)"
	menu.custom_minimum_size = Vector2(0, 40)
	menu.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(menu, UiKit.PANEL, UiKit.BORDER)
	menu.pressed.connect(func() -> void: SceneFlow.goto_main_menu())
	_root_box.add_child(menu)


# ---------------------------------------------------------------------------
# Shared pieces
# ---------------------------------------------------------------------------

func _add_header() -> void:
	_root_box.add_child(UiKit.label("The Moment of Recall", 26, UiKit.INK))
	var creed := UiKit.label("While alive, the character forgets. At death, the soul remembers.", 13, UiKit.MUTED)
	creed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root_box.add_child(creed)

	if _report != null:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UiKit.stylebox(Color(0.08, 0.10, 0.12), UiKit.BORDER))
		_root_box.add_child(panel)
		var pad := MarginContainer.new()
		for side in ["left", "top", "right", "bottom"]:
			pad.add_theme_constant_override("margin_%s" % side, 14)
		panel.add_child(pad)
		var report_box := VBoxContainer.new()
		report_box.add_theme_constant_override("separation", 4)
		pad.add_child(report_box)
		var killer := _report.killer_name if not _report.killer_name.is_empty() else "the coast itself"
		report_box.add_child(UiKit.label("Life %d — slain by %s, %d of %d rows into the %s." % [
			_report.life_number, killer, _report.rows_survived, maxi(0, _report.total_rows - 1), _report.universe_id.replace("_", " "),
		], 14, UiKit.INK))
		var feats: Array[String] = []
		if _report.elites_defeated > 0:
			feats.append("%d elite%s defeated" % [_report.elites_defeated, "" if _report.elites_defeated == 1 else "s"])
		if _report.boss_reached:
			feats.append("reached the source of the light")
		if _report.carried_item_tags.has("forbidden"):
			feats.append("carried forbidden knowledge")
		if not feats.is_empty():
			report_box.add_child(UiKit.label("The soul remembers: " + ", ".join(feats) + ".", 12, UiKit.MUTED))
		report_box.add_child(UiKit.label("+%d Remembrance" % _report.remembrance, 15, UiKit.AMBER))

	var rule := HSeparator.new()
	_root_box.add_child(rule)


func _clear_box() -> void:
	for child in _root_box.get_children():
		child.queue_free()
		_root_box.remove_child(child)


func _build_frame() -> void:
	add_child(UiKit.background(Color(0.03, 0.045, 0.06)))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 0)
	panel.add_theme_stylebox_override("panel", UiKit.stylebox(UiKit.PANEL, UiKit.BORDER, 1, 12))
	center.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 30)
	panel.add_child(pad)
	_root_box = VBoxContainer.new()
	_root_box.add_theme_constant_override("separation", 12)
	pad.add_child(_root_box)

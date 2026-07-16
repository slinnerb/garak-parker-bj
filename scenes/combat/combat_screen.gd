extends Control
## Combat screen (Phase 3b): the first on-screen, playable surface.
##
## This is presentation only — it renders a CombatState and sends player commands
## (play_card / end_player_turn); every rule lives in the domain engine
## (docs/DECISIONS.md, combat architecture). The whole UI is built in code so the
## dynamic parts (a hand and an enemy row that change every action) and the
## static frame share one styling vocabulary.
##
## For now it runs a self-contained demo fight (CombatDemo). When the run/map
## flow lands it will instead render the CombatState handed to it by the run.

# --- Palette (drowned-coast dusk; consistent with the menu) ---
const BG := Color(0.055, 0.07, 0.092)
const PANEL := Color(0.10, 0.13, 0.15)
const PANEL_HI := Color(0.14, 0.18, 0.20)
const BORDER := Color(0.20, 0.27, 0.29)
const BORDER_HI := Color(0.85, 0.62, 0.30)
const INK := Color(0.91, 0.89, 0.83)
const MUTED := Color(0.60, 0.68, 0.65)
const AMBER := Color(0.87, 0.64, 0.32)
const HP_FILL := Color(0.55, 0.32, 0.30)
const HP_BG := Color(0.16, 0.11, 0.11)
const BLOCK := Color(0.55, 0.72, 0.82)
const DANGER := Color(0.80, 0.40, 0.34)
const GOOD_GREEN := Color(0.62, 0.78, 0.60)

# Card accent by type.
const CARD_COLORS := {
	"attack": Color(0.78, 0.38, 0.33),
	"skill": Color(0.38, 0.56, 0.68),
	"power": Color(0.56, 0.44, 0.70),
	"status": Color(0.46, 0.48, 0.46),
	"curse": Color(0.42, 0.40, 0.46),
}

var _combat: CombatState
var _seed: int = 0
var _pending_card_index: int = -1   # a card awaiting a target click, or -1
## The fight to build (archetype/attuned items/enemy), from the attunement
## screen. Empty => the default demo. Kept so "Fight Again" reuses the loadout.
var _request: Dictionary = {}
## True when this fight is part of an active run (deck/HP/enemy come from the
## RunState, and the outcome feeds back into the run rather than a demo replay).
var _in_run: bool = false

# Node references (built in _build_ui).
var _title_label: Label
var _seed_label: Label
var _enemy_row: HBoxContainer
var _hand_row: HBoxContainer
var _log_label: RichTextLabel
var _stats_label: RichTextLabel
var _hint_label: Label
var _end_turn_button: Button
var _outcome_overlay: Control
var _outcome_label: Label
var _outcome_buttons: HBoxContainer


func _ready() -> void:
	# Standalone safety: the boot scene loads content, but this screen can be run
	# directly (e.g. the screenshot tool), so ensure content exists.
	if ContentRegistry.ids_of("card").is_empty():
		ContentLoader.load_all(ContentRegistry)
	_request = CombatRequest.take()
	_build_ui()
	_start_new_fight()


# ---------------------------------------------------------------------------
# Fight lifecycle
# ---------------------------------------------------------------------------

func _start_new_fight() -> void:
	var run_node := _run_combat_node()
	if run_node != null:
		# A fight inside the current run: deck, HP and enemy come from the run,
		# seeded so the same encounter always plays the same way.
		_in_run = true
		_seed = RunManager.encounter_seed(RunManager.current.current_node_id)
		_combat = RunCombat.build(ContentRegistry, RunManager.current, RngStream.new(_seed))
	else:
		_in_run = false
		_seed = RNG.fresh_seed()
		var rng := RngStream.new(_seed)
		if _request.is_empty():
			_combat = CombatDemo.build(ContentRegistry, rng)
		else:
			_combat = CombatDemo.build_from(ContentRegistry, rng,
				str(_request.get("archetype_id", CombatDemo.DEMO_ARCHETYPE)),
				_request.get("attuned_item_ids", CombatDemo.DEFAULT_ATTUNED),
				str(_request.get("enemy_id", CombatDemo.DEMO_ENEMY)))
	_pending_card_index = -1
	_outcome_overlay.visible = false
	if _combat == null:
		_hint_label.text = "This fight could not be set up."
		return
	_combat.start_combat()
	_seed_label.text = "seed %d" % _seed
	_refresh_all()


## The current run's node if it's a fight to render, else null.
func _run_combat_node() -> MapNode:
	if not RunManager.has_run():
		return null
	var node: MapNode = RunManager.current.current_node()
	if node != null and RunCombat.is_combat_node(node.node_type):
		return node
	return null


func _refresh_all() -> void:
	_refresh_enemies()
	_refresh_hand()
	_refresh_stats()
	_refresh_log()
	_refresh_hint()
	_end_turn_button.disabled = _combat.is_over()
	if _combat.is_over():
		_show_outcome()


# ---------------------------------------------------------------------------
# Player commands
# ---------------------------------------------------------------------------

func _on_card_pressed(index: int) -> void:
	if _combat.is_over() or not _combat.can_play(index):
		return
	var card: CardInstance = _combat.player.hand[index]
	if card.definition.targeting == "enemy":
		# Needs a target: arm the card and wait for an enemy click.
		_pending_card_index = index
		_refresh_hint()
		_refresh_enemies()  # re-render so targets show as selectable
		return
	_combat.play_card(index, -1)
	_pending_card_index = -1
	_refresh_all()


func _on_enemy_clicked(index: int) -> void:
	if _pending_card_index < 0:
		return
	_combat.play_card(_pending_card_index, index)
	_pending_card_index = -1
	_refresh_all()


func _on_end_turn_pressed() -> void:
	if _combat.is_over():
		return
	_pending_card_index = -1
	_combat.end_player_turn()
	_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	# Escape cancels a pending target selection.
	if _pending_card_index >= 0 and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_pending_card_index = -1
		_refresh_hint()
		_refresh_enemies()
		accept_event()


# ---------------------------------------------------------------------------
# Rendering — enemies
# ---------------------------------------------------------------------------

func _refresh_enemies() -> void:
	_clear(_enemy_row)
	for i in _combat.enemies.size():
		_enemy_row.add_child(_make_enemy_view(_combat.enemies[i], i))


func _make_enemy_view(enemy: EnemyState, index: int) -> Control:
	var targeting := _pending_card_index >= 0 and enemy.is_alive()
	var panel := Button.new()
	panel.custom_minimum_size = Vector2(240, 196)
	panel.focus_mode = Control.FOCUS_NONE
	panel.disabled = not targeting
	var border := BORDER_HI if targeting else BORDER
	_style_button(panel, PANEL if enemy.is_alive() else Color(0.09, 0.10, 0.11), border, targeting)
	panel.pressed.connect(_on_enemy_clicked.bind(index))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	panel.add_child(box)

	box.add_child(_label(enemy.display_name, 18, INK if enemy.is_alive() else MUTED))

	if enemy.is_alive():
		var hp_bar := ProgressBar.new()
		hp_bar.max_value = enemy.max_hp
		hp_bar.value = enemy.hp
		hp_bar.show_percentage = false
		hp_bar.custom_minimum_size = Vector2(0, 20)
		_style_bar(hp_bar, HP_BG, HP_FILL)
		box.add_child(hp_bar)
		box.add_child(_label("%d / %d HP" % [enemy.hp, enemy.max_hp], 13, MUTED))
		if enemy.block > 0:
			box.add_child(_label("Block %d" % enemy.block, 14, BLOCK))
		box.add_child(_label(_format_intent(enemy.current_intent), 14, AMBER))
		var telegraph := enemy.current_intent.telegraph if enemy.current_intent != null else ""
		if not telegraph.is_empty():
			var tl := _label(telegraph, 12, MUTED)
			tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(tl)
		var statuses := _format_statuses(enemy)
		if not statuses.is_empty():
			box.add_child(_label(statuses, 12, DANGER))
	else:
		box.add_child(_label("Defeated", 14, MUTED))

	_ignore_mouse(box)
	return panel


func _format_intent(intent: EnemyIntentDefinition) -> String:
	if intent == null:
		return "…"
	match intent.kind:
		"attack":
			var times := "×%d" % intent.times if intent.times > 1 else ""
			return "⚔ Attack %d%s" % [intent.amount, times]
		"defend":
			return "◆ Defend %d" % intent.amount
		"buff":
			return "▲ Strengthen (%s)" % intent.status_id
		"debuff":
			return "▼ Afflict (%s)" % intent.status_id
		_:
			return "✦ Unknown"


# ---------------------------------------------------------------------------
# Rendering — hand
# ---------------------------------------------------------------------------

func _refresh_hand() -> void:
	_clear(_hand_row)
	for i in _combat.player.hand.size():
		var playable := _combat.can_play(i)
		_hand_row.add_child(_make_card_view(_combat.player.hand[i], i, playable))


func _make_card_view(card: CardInstance, index: int, playable: bool) -> Control:
	var def := card.definition
	var accent: Color = CARD_COLORS.get(def.card_type, MUTED)
	var selected := index == _pending_card_index

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(162, 202)
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = not playable
	btn.tooltip_text = def.description
	_style_button(btn, PANEL_HI if playable else Color(0.09, 0.11, 0.12), BORDER_HI if selected else accent, selected)
	btn.pressed.connect(_on_card_pressed.bind(index))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 11
	box.offset_top = 9
	box.offset_right = -11
	box.offset_bottom = -9
	btn.add_child(box)

	var header := HBoxContainer.new()
	var cost := _label("◈ %d" % def.energy_cost, 15, AMBER)
	header.add_child(cost)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(_label(def.card_type.to_upper(), 10, accent))
	box.add_child(header)

	var name_label := _label(def.display_name, 15, INK if playable else MUTED)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)

	var rule := HSeparator.new()
	box.add_child(rule)

	var desc := _label(_card_body_text(def), 12, MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)

	_ignore_mouse(box)
	return btn


## A short, readable effect summary for the card face (the flavour lives in the
## tooltip). Falls back to the flavour text for cards with no effects.
func _card_body_text(def: CardDefinition) -> String:
	var parts: Array[String] = []
	for effect in def.effects:
		var line := _describe_effect(effect)
		if not line.is_empty():
			parts.append(line)
	if parts.is_empty():
		return def.description
	return "\n".join(parts)


func _describe_effect(effect: CardEffectDefinition) -> String:
	var p: Dictionary = effect.params
	match effect.kind:
		"deal_damage":
			var times := " ×%d" % int(p.get("times", 1)) if int(p.get("times", 1)) > 1 else ""
			return "Deal %d%s damage" % [int(p.get("amount", 0)), times]
		"gain_block":
			return "Gain %d block" % int(p.get("amount", 0))
		"heal":
			return "Heal %d" % int(p.get("amount", 0))
		"draw_cards":
			return "Draw %d" % int(p.get("count", 0))
		"apply_status":
			return "Apply %d %s" % [int(p.get("stacks", 1)), str(p.get("status_id", ""))]
		"remove_status":
			return "Cleanse %s" % str(p.get("status_id", ""))
		"repeat":
			return "%d× a strike" % int(p.get("times", 1))
		"conditional":
			return "A chance of more"
		_:
			return ""


# ---------------------------------------------------------------------------
# Rendering — stats, log, hint, outcome
# ---------------------------------------------------------------------------

func _refresh_stats() -> void:
	var p := _combat.player
	_stats_label.text = "[b]%s[/b]   ❤ %d/%d   ◆ %d   ◈ %d/%d      [color=#8b978f]draw %d · discard %d · exhaust %d · turn %d[/color]" % [
		p.display_name, p.hp, p.max_hp, p.block, p.energy, p.max_energy,
		p.draw_pile.size(), p.discard_pile.size(), p.exhaust_pile.size(), _combat.turn_number,
	]


func _refresh_log() -> void:
	var lines := _combat.log
	var start := maxi(0, lines.size() - 40)
	var shown: Array[String] = []
	for i in range(start, lines.size()):
		shown.append(lines[i])
	_log_label.text = "\n".join(shown)
	_log_label.scroll_to_line(maxi(0, _log_label.get_line_count() - 1))


func _refresh_hint() -> void:
	if _combat.is_over():
		_hint_label.text = ""
	elif _pending_card_index >= 0:
		_hint_label.text = "Choose a target  ·  Esc to cancel"
		_hint_label.add_theme_color_override("font_color", AMBER)
	else:
		_hint_label.text = "Play a card, or end your turn"
		_hint_label.add_theme_color_override("font_color", MUTED)


func _show_outcome() -> void:
	if _outcome_overlay.visible:
		return  # already resolved this fight
	_outcome_overlay.visible = true
	for child in _outcome_buttons.get_children():
		child.queue_free()
		_outcome_buttons.remove_child(child)

	if _in_run:
		_show_run_outcome()
		return

	# Standalone demo fight.
	if _combat.is_victory():
		_outcome_label.text = "The tide pulls back.\nYou survive — this time."
		_outcome_label.add_theme_color_override("font_color", GOOD_GREEN)
	else:
		_outcome_label.text = "The water closes over.\nThis life ends here."
		_outcome_label.add_theme_color_override("font_color", DANGER)
	_add_outcome_button("Fight Again", _start_new_fight, true)
	_add_outcome_button("Return to Menu", func() -> void: SceneFlow.goto_main_menu(), false)


func _show_run_outcome() -> void:
	var run := RunManager.current
	# Carry the fight's result back into the run (surviving HP; 0 = death).
	run.resolve_combat(_combat.player.hp)
	if run.is_victory():
		_outcome_label.text = "The lighthouse goes dark at last.\nThis life ends — but it ends victorious."
		_outcome_label.add_theme_color_override("font_color", GOOD_GREEN)
		_add_outcome_button("Complete the Run", func() -> void:
			RunManager.end_run()
			SceneFlow.goto_main_menu(), true)
	elif run.is_defeat():
		_outcome_label.text = "The water closes over.\nThis life ends here — the soul drifts on."
		_outcome_label.add_theme_color_override("font_color", DANGER)
		_add_outcome_button("Let go", func() -> void:
			RunManager.end_run()
			SceneFlow.goto_main_menu(), true)
	else:
		_outcome_label.text = "The way is clear.\nYou press deeper into the coast."
		_outcome_label.add_theme_color_override("font_color", GOOD_GREEN)
		_add_outcome_button("Onward  ⟶", func() -> void: SceneFlow.goto_map(), true)


func _add_outcome_button(text: String, callback: Callable, emphasized: bool) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(170, 44)
	btn.focus_mode = Control.FOCUS_NONE
	_style_button(btn, Color(0.16, 0.13, 0.08) if emphasized else PANEL, AMBER if emphasized else BORDER, emphasized)
	btn.pressed.connect(callback)
	_outcome_buttons.add_child(btn)


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 22)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# Top bar: back | title | seed
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	var back := Button.new()
	back.text = "⟵ Menu"
	back.focus_mode = Control.FOCUS_NONE
	_style_button(back, PANEL, BORDER, false)
	back.pressed.connect(func() -> void: SceneFlow.goto_main_menu())
	top.add_child(back)
	_title_label = _label("Lovecraftian Coast — a fight on the tideline", 18, INK)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_title_label)
	_seed_label = _label("", 12, MUTED)
	top.add_child(_seed_label)

	# Enemy row
	_enemy_row = HBoxContainer.new()
	_enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_row.add_theme_constant_override("separation", 26)
	_enemy_row.custom_minimum_size = Vector2(0, 210)
	root.add_child(_enemy_row)

	# Middle: combat log on the left, breathing room on the right
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	root.add_child(mid)
	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size = Vector2(440, 0)
	log_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.08, 0.10, 0.12), BORDER))
	mid.add_child(log_panel)
	var log_margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		log_margin.add_theme_constant_override("margin_%s" % side, 12)
	log_panel.add_child(log_margin)
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = false
	_log_label.scroll_following = true
	_log_label.add_theme_color_override("default_color", MUTED)
	_log_label.add_theme_font_size_override("normal_font_size", 13)
	log_margin.add_child(_log_label)
	var mid_spacer := Control.new()
	mid_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(mid_spacer)

	# Hand
	_hand_row = HBoxContainer.new()
	_hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_hand_row.add_theme_constant_override("separation", 10)
	_hand_row.custom_minimum_size = Vector2(0, 206)
	root.add_child(_hand_row)

	# Bottom bar: stats | hint | end turn
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	root.add_child(bottom)
	_stats_label = RichTextLabel.new()
	_stats_label.bbcode_enabled = true
	_stats_label.fit_content = true
	_stats_label.scroll_active = false
	_stats_label.custom_minimum_size = Vector2(680, 28)
	_stats_label.add_theme_color_override("default_color", INK)
	_stats_label.add_theme_font_size_override("normal_font_size", 15)
	_stats_label.add_theme_font_size_override("bold_font_size", 15)
	bottom.add_child(_stats_label)
	_hint_label = _label("", 14, MUTED)
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_hint_label)
	_end_turn_button = Button.new()
	_end_turn_button.text = "End Turn"
	_end_turn_button.custom_minimum_size = Vector2(150, 44)
	_end_turn_button.focus_mode = Control.FOCUS_NONE
	_style_button(_end_turn_button, Color(0.16, 0.13, 0.08), AMBER, false)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	bottom.add_child(_end_turn_button)

	_build_outcome_overlay()


func _build_outcome_overlay() -> void:
	_outcome_overlay = Control.new()
	_outcome_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_outcome_overlay.visible = false
	add_child(_outcome_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_outcome_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_outcome_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(PANEL, BORDER, 1, 10))
	center.add_child(panel)

	var pad := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 34)
	panel.add_child(pad)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	pad.add_child(box)

	_outcome_label = _label("", 22, INK)
	_outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_outcome_label)

	# Buttons are populated per-outcome (run vs demo) in _show_outcome.
	_outcome_buttons = HBoxContainer.new()
	_outcome_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_outcome_buttons.add_theme_constant_override("separation", 12)
	box.add_child(_outcome_buttons)


# ---------------------------------------------------------------------------
# Small UI helpers
# ---------------------------------------------------------------------------

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _stylebox(bg: Color, border: Color, border_w: int = 1, radius: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


## Applies normal/hover/pressed/disabled styleboxes to a Button. `emphasized`
## thickens the border (used for the selected card and targetable enemies).
func _style_button(btn: Button, bg: Color, border: Color, emphasized: bool) -> void:
	var w := 2 if emphasized else 1
	var normal := _stylebox(bg, border, w)
	var hover := _stylebox(bg.lightened(0.06), border.lightened(0.15), maxi(w, 2))
	var pressed := _stylebox(bg.darkened(0.08), border, w)
	var disabled := _stylebox(bg.darkened(0.10), BORDER.darkened(0.2), 1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", _stylebox(bg, border, w))
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", MUTED.darkened(0.1))


func _style_bar(bar: ProgressBar, bg: Color, fill: Color) -> void:
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = bg
	bg_sb.set_corner_radius_all(3)
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = fill
	fill_sb.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg_sb)
	bar.add_theme_stylebox_override("fill", fill_sb)


func _format_statuses(c: Combatant) -> String:
	var parts: Array[String] = []
	for status_id in c.statuses:
		var def = ContentRegistry.get_def("status", status_id)
		var status_name: String = def.display_name if def != null else str(status_id)
		parts.append("%s %d" % [status_name, c.get_status(status_id)])
	return "  ·  ".join(parts)


## Recursively makes a control tree transparent to the mouse, so clicks fall
## through label/box children to the Button that owns them.
func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
		node.remove_child(child)

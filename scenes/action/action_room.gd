extends Node2D
## Action Combat Arc — Phase A + B vertical slice.
##
## A top-down arena where you move, dodge, and slow time to plan. Phase A gave the
## real-time core + freeze (FocusMeter); Phase B makes the freeze meaningful: your
## attuned loadout is a hand of cards you QUEUE during the freeze (keys 1-4) and
## UNLEASH in a burst when you release it. Free spirit-bolt (LMB) stays your basic
## attack; cards are the specials. Everything is a tunable prototype whose job is
## to find the *feel* before rooms/boons/real attunement wire in (roadmap C+).

const SpiritPlayer := preload("res://scenes/action/spirit_player.gd")
const ActionEnemy := preload("res://scenes/action/action_enemy.gd")
const SpiritBolt := preload("res://scenes/action/spirit_bolt.gd")
const ActionCardScript := preload("res://gameplay/action/action_card.gd")
const CardLoadoutScript := preload("res://gameplay/action/card_loadout.gd")
const RunCombatScript := preload("res://gameplay/combat/run_combat.gd")
const ActionHandScript := preload("res://gameplay/action/action_hand.gd")
const FloatingText := preload("res://scenes/action/floating_text.gd")

const VIEW := Vector2(1280, 720)
const ARENA := Rect2(70, 110, 1140, 470)  # play bounds within the view

const MAX_QUEUE := 6
const CAST_GAP := 0.16       # real-time beat between queued cards on execute
const LASH_RANGE := 96.0
# Rip Tide only lands where the lunge can actually arrive (max lunge + reach).
const RIPTIDE_RANGE := 210.0

var focus := FocusMeter.new()
var time_factor := 1.0                     # read by the enemy each physics frame
var _shake := 0.0                          # screen-shake magnitude, decays over time

var _loadout = null                        # CardLoadout
var _queue: Array = []                      # card indices queued this plan
var _pending: Array = []                    # ActionCards awaiting sequenced cast
var _cast_timer := 0.0
var _planning := false

var _player = null
var _enemy = null
var _over := false

# Run context (set when launched from a run map node; empty for the dev sandbox).
var _in_run := false
var _run = null
var _enemy_def = null
var _enemy_name := "The Drowned One"

var _p_hp_fill: ColorRect
var _shield_fill: ColorRect
var _focus_fill: ColorRect
var _focus_label: Label
var _e_hp_fill: ColorRect
var _e_hp_box: Control
var _vignette: ColorRect
var _plan_hint: Label
var _card_panels: Array = []
var _overlay: Control
var _overlay_title: Label
var _overlay_vbox: VBoxContainer


func _ready() -> void:
	_ensure_input_actions()
	_resolve_run_context()
	_loadout = CardLoadoutScript.new(_build_hand())
	_build_background()
	_spawn_actors()
	_build_hud()


## Loot → hand: in a run, the freeze cards come from what you've actually
## attuned (items found on the map change how you fight). The dev sandbox — or a
## run with nothing attuned — falls back to the default hand, never fighting bare.
func _build_hand() -> Array:
	if _in_run and _run != null:
		var hand: Array = ActionHandScript.build_hand(ContentRegistry, _run.attunement)
		if not hand.is_empty():
			return hand
	return ActionCardScript.default_hand()


## If launched from a run's combat/elite/boss node, pull the fight from the run:
## the enemy comes from the universe pool by node type, HP carries in. Otherwise
## this is the standalone dev sandbox (default specter vs. The Drowned One).
func _resolve_run_context() -> void:
	if not RunManager.has_run():
		return
	var run = RunManager.current
	var node = run.current_node()
	if node == null or not RunCombatScript.is_combat_node(node.node_type):
		return
	if ContentRegistry.ids_of("enemy").is_empty():
		ContentLoader.load_all(ContentRegistry)
	var rng := RngStream.new(RunManager.encounter_seed(node.id))
	var enemy_id: String = RunCombatScript._pick_enemy(ContentRegistry, run.universe_id, node.node_type, rng)
	if enemy_id.is_empty():
		return
	var def = ContentRegistry.get_def("enemy", enemy_id)
	if def == null:
		return
	_in_run = true
	_run = run
	_enemy_def = def
	_enemy_name = def.display_name


# --- Services the actors call back into -----------------------------------

func clamp_to_arena(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, ARENA.position.x, ARENA.end.x),
		clampf(pos.y, ARENA.position.y, ARENA.end.y))


func spawn_projectile(node: Node) -> void:
	add_child(node)


# --- Loop ------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _over:
		return
	_loadout.tick(delta)

	var wants: bool = Input.is_action_pressed("focus") and _player != null and not _player.is_dead()
	focus.update(delta, wants)
	time_factor = focus.time_factor()

	# Plan-mode edges: entering clears the queue, leaving unleashes it.
	if focus.active and not _planning:
		_planning = true
		_queue.clear()
	elif not focus.active and _planning:
		_planning = false
		_execute_queue()

	# Sequenced burst on release.
	if not _pending.is_empty():
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_resolve_card(_pending.pop_front())
			_cast_timer = CAST_GAP


func _unhandled_input(event: InputEvent) -> void:
	if _over or not _planning:
		return
	for i in _loadout.size():
		if event.is_action_pressed("card_%d" % (i + 1)):
			_try_queue(i)


func _process(delta: float) -> void:
	_refresh_hud()
	# Screen shake: offset the world root (the HUD lives on a CanvasLayer, so it
	# stays put). randf is fine at runtime — this isn't the deterministic sim.
	if _shake > 0.5:
		position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = maxf(0.0, _shake - 60.0 * delta)
	elif position != Vector2.ZERO:
		position = Vector2.ZERO


# --- Damage juice ----------------------------------------------------------

func _on_enemy_damaged(amount: float, at: Vector2) -> void:
	_spawn_number(amount, at + Vector2(0, -26), Color(1.0, 0.86, 0.5))


func _on_player_damaged(amount: float, at: Vector2) -> void:
	_spawn_number(amount, at + Vector2(0, -26), Color(1.0, 0.5, 0.46))
	_shake = maxf(_shake, clampf(amount * 0.55, 4.0, 14.0))


func _spawn_number(amount: float, at: Vector2, color: Color) -> void:
	var ft := FloatingText.new()
	ft.position = at
	ft.setup(str(int(round(amount))), color)
	add_child(ft)


func _draw() -> void:
	draw_rect(ARENA, Color(0.06, 0.09, 0.12))
	draw_rect(ARENA, Color(0.18, 0.28, 0.32), false, 2.0)


# --- Cards: queue + execute ------------------------------------------------

func _try_queue(index: int) -> void:
	if _queue.size() >= MAX_QUEUE or _queue.has(index) or not _loadout.is_ready(index):
		return
	_queue.append(index)


func _execute_queue() -> void:
	if _queue.is_empty():
		return
	_cast_timer = 0.0  # the first card of a burst fires the moment you release
	for i in _queue:
		_loadout.use(i)
		_pending.append(_loadout.cards[i])
	_queue.clear()


func _resolve_card(card) -> void:
	if _player == null or not is_instance_valid(_player) or _player.is_dead():
		return
	match card.kind:
		ActionCardScript.BOLT:
			_fire_card_bolt(card)
		ActionCardScript.LASH:
			if _enemy != null and is_instance_valid(_enemy) and _player.position.distance_to(_enemy.position) <= LASH_RANGE:
				_enemy.take_damage(card.power, _player.position)
		ActionCardScript.WARD:
			_player.add_shield(card.power)
		ActionCardScript.HEAL:
			_player.heal(card.power)
		ActionCardScript.RIPTIDE:
			if _enemy != null and is_instance_valid(_enemy):
				_player.dash_toward(_enemy.position)
				if _player.position.distance_to(_enemy.position) <= RIPTIDE_RANGE:
					_enemy.take_damage(card.power, _player.position)


func _fire_card_bolt(card) -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		return
	var bolt := SpiritBolt.new()
	bolt.position = _player.position
	bolt.setup(_enemy.position - _player.position, card.power)
	add_child(bolt)


# --- Setup -----------------------------------------------------------------

func _spawn_actors() -> void:
	_player = SpiritPlayer.new()
	_player.position = Vector2(ARENA.position.x + 240, ARENA.get_center().y)
	_player.room = self
	add_child(_player)

	_enemy = ActionEnemy.new()
	_enemy.position = Vector2(ARENA.end.x - 240, ARENA.get_center().y)
	_enemy.room = self
	_enemy.target = _player
	add_child(_enemy)

	# Carry the run in: the specter's HP persists, the enemy is the node's foe.
	if _in_run and _run != null:
		_player.max_hp = float(_run.max_hp)
		_player.hp = float(clampi(_run.hp, 1, _run.max_hp))
	if _in_run and _enemy_def != null:
		_enemy.configure(_enemy_def)

	_player.died.connect(_on_player_died)
	_enemy.died.connect(_on_enemy_died)
	_player.damaged.connect(_on_player_damaged)
	_enemy.damaged.connect(_on_enemy_damaged)


func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	layer.add_child(UiKit.background(Color(0.03, 0.045, 0.06)))


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	_vignette = ColorRect.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.color = Color(0.18, 0.42, 0.68, 0.0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_vignette)

	# Player HP + shield + focus (top-left).
	root.add_child(_hud_label("THE SPECTER", Vector2(28, 22), 16, UiKit.INK))
	_p_hp_fill = _make_bar(root, Vector2(28, 48), Vector2(320, 18), Color(0.82, 0.34, 0.38))
	# Shield: a thin cyan strip along the top edge of the HP bar (no own bg, so it
	# layers over health rather than hiding it).
	_shield_fill = ColorRect.new()
	_shield_fill.position = Vector2(28, 48)
	_shield_fill.size = Vector2(0, 5)
	_shield_fill.color = Color(0.58, 0.88, 0.82, 0.95)
	_shield_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield_fill.set_meta("w", 320.0)
	root.add_child(_shield_fill)
	root.add_child(_hud_label("FOCUS", Vector2(28, 74), 12, UiKit.MUTED))
	_focus_fill = _make_bar(root, Vector2(90, 74), Vector2(258, 14), UiKit.AMBER)
	_focus_label = _hud_label("◊ TIME SLOWS ◊", Vector2(0, 96), 13, Color(0.7, 0.9, 1.0))
	_focus_label.size.x = VIEW.x
	_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_label.visible = false
	root.add_child(_focus_label)

	# Enemy HP (top-centre).
	_e_hp_box = Control.new()
	_e_hp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_e_hp_box)
	var e_label := _hud_label(_enemy_name.to_upper(), Vector2(VIEW.x * 0.5 - 150, 22), 15, UiKit.DANGER)
	e_label.size.x = 300
	e_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_hp_box.add_child(e_label)
	_e_hp_fill = _make_bar(_e_hp_box, Vector2(VIEW.x * 0.5 - 150, 48), Vector2(300, 16), UiKit.DANGER)

	_build_hand_hud(root)

	var hint := _hud_label(
		"WASD move    SPACE dodge    LMB/J bolt    RMB/K hold to FOCUS    1-%d queue cards, release to unleash" % _loadout.size(),
		Vector2(0, VIEW.y - 30), 13, UiKit.MUTED)
	hint.size.x = VIEW.x
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	_build_overlay(layer)


func _build_hand_hud(root: Control) -> void:
	_card_panels.clear()
	var n: int = _loadout.size()
	var cw := 178.0
	var ch := 100.0
	var gap := 12.0
	var total := n * cw + (n - 1) * gap
	var start_x := (VIEW.x - total) * 0.5
	var y := VIEW.y - 156.0

	for i in n:
		var card = _loadout.cards[i]
		var x := start_x + i * (cw + gap)
		var panel := Panel.new()
		panel.position = Vector2(x, y)
		panel.size = Vector2(cw, ch)
		panel.add_theme_stylebox_override("panel", UiKit.stylebox(UiKit.PANEL, card.color, 2, 8))
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(panel)

		# A keycap so it's obvious which key fires this card.
		var keycap := Panel.new()
		keycap.position = Vector2(10, 9)
		keycap.size = Vector2(30, 26)
		keycap.add_theme_stylebox_override("panel", UiKit.stylebox(UiKit.PANEL_HI, card.color, 1, 5))
		panel.add_child(keycap)
		var keynum := UiKit.label(str(i + 1), 16, UiKit.INK)
		keynum.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		keynum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		keynum.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		keycap.add_child(keynum)

		var nm := UiKit.label(card.display_name, 15, card.color.lerp(UiKit.INK, 0.3))
		nm.position = Vector2(48, 12)
		panel.add_child(nm)

		var desc := UiKit.label(card.description, 12, UiKit.INK.darkened(0.06))
		desc.position = Vector2(12, 44)
		desc.custom_minimum_size = Vector2(cw - 24, 0)
		desc.size = Vector2(cw - 24, 34)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(desc)

		var stat := UiKit.label(_card_stat(card), 11, card.color)
		stat.position = Vector2(12, ch - 22)
		panel.add_child(stat)

		var shade := ColorRect.new()
		shade.color = Color(0.03, 0.04, 0.05, 0.72)
		shade.position = Vector2.ZERO
		shade.size = Vector2(cw, ch)
		panel.add_child(shade)

		var badge := UiKit.label("", 17, UiKit.AMBER)
		badge.position = Vector2(cw - 22, 6)
		panel.add_child(badge)

		UiKit.ignore_mouse(panel)
		_card_panels.append({"panel": panel, "shade": shade, "badge": badge, "h": ch})

	_plan_hint = UiKit.label("◊ TIME SLOWS — press 1-%d to queue cards, release FOCUS to unleash ◊" % _loadout.size(), 13, Color(0.72, 0.92, 1.0))
	_plan_hint.position = Vector2(0, y - 26)
	_plan_hint.size.x = VIEW.x
	_plan_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plan_hint.visible = false
	root.add_child(_plan_hint)


func _card_stat(card) -> String:
	match card.kind:
		ActionCardScript.WARD:
			return "+%d shield" % int(card.power)
		ActionCardScript.HEAL:
			return "+%d HP" % int(card.power)
		ActionCardScript.RIPTIDE:
			return "%d dmg · dash in" % int(card.power)
		ActionCardScript.LASH:
			return "%d dmg · melee" % int(card.power)
		_:
			return "%d dmg · ranged" % int(card.power)


func _build_overlay(layer: CanvasLayer) -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	layer.add_child(_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.045, 0.78)
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	_overlay_vbox = VBoxContainer.new()
	_overlay_vbox.add_theme_constant_override("separation", 16)
	_overlay_vbox.custom_minimum_size = Vector2(460, 0)
	center.add_child(_overlay_vbox)
	_overlay_title = UiKit.label("", 24, UiKit.INK)
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_title.custom_minimum_size = Vector2(460, 0)
	_overlay_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overlay_vbox.add_child(_overlay_title)


# --- HUD refresh -----------------------------------------------------------

func _refresh_hud() -> void:
	if _player != null and is_instance_valid(_player):
		_set_bar(_p_hp_fill, _player.hp / _player.max_hp)
		_set_bar(_shield_fill, _player.shield / _player.max_hp)
	if _enemy != null and is_instance_valid(_enemy):
		_set_bar(_e_hp_fill, _enemy.hp / _enemy.max_hp)
	elif _e_hp_box != null:
		_e_hp_box.visible = false

	_set_bar(_focus_fill, focus.fraction())
	_focus_fill.color = UiKit.DANGER if focus.is_recharging() else (Color(0.55, 0.85, 1.0) if focus.active else UiKit.AMBER)
	_focus_label.visible = focus.active
	_vignette.color.a = lerpf(_vignette.color.a, 0.22 if focus.active else 0.0, 0.25)

	if _plan_hint != null:
		_plan_hint.visible = _planning
	for i in _card_panels.size():
		var cp: Dictionary = _card_panels[i]
		var shade: ColorRect = cp["shade"]
		shade.size.y = float(cp["h"]) * _loadout.cooldown_fraction(i)
		var pos := _queue.find(i)
		cp["badge"].text = str(pos + 1) if pos >= 0 else ""


# --- End state -------------------------------------------------------------

func _on_enemy_died() -> void:
	if _over:
		return  # a trailing bolt after the fight is decided changes nothing
	if _in_run and _run != null:
		_run.resolve_combat(int(_player.hp))
		if _run.is_victory():
			_finish("The lighthouse goes dark at last.\nThis life ends — but it ends victorious.", UiKit.GOOD, [
				{"label": "Complete the run", "cb": func() -> void:
					RunManager.end_run()
					SceneFlow.goto_main_menu()}])
		else:
			_finish("The way is clear.\nYou press deeper into the coast.", UiKit.GOOD, [
				{"label": "Onward  ⟶", "cb": func() -> void: SceneFlow.goto_map()}])
	else:
		_finish("%s is unmade.\nThe deep is quiet — for now." % _enemy_name, UiKit.GOOD, _sandbox_buttons())


func _on_player_died() -> void:
	if _over:
		return
	if _in_run and _run != null:
		_finish("The water closes over.\nAnd at the moment of death… the soul remembers.", UiKit.DANGER, [
			{"label": "Remember  ⟶", "cb": func() -> void:
				RunManager.report_death(_enemy_def)
				SceneFlow.goto_recall()}])
	else:
		_finish("You are dragged back into the dark.\nThe soul does not end — it only tries again.", UiKit.DANGER, _sandbox_buttons())


func _sandbox_buttons() -> Array:
	return [
		{"label": "Fight again", "cb": func() -> void: get_tree().reload_current_scene()},
		{"label": "Back to menu", "cb": func() -> void: SceneFlow.goto_main_menu()},
	]


func _finish(title: String, color: Color, buttons: Array) -> void:
	if _over:
		return
	_over = true
	time_factor = 1.0
	# The freeze ends with the fight: clear focus/plan state so the HUD returns
	# to idle (no stuck TIME SLOWS / vignette / queue badges over the overlay).
	focus.active = false
	_planning = false
	_queue.clear()
	_pending.clear()
	_vignette.color.a = 0.0
	if _player != null and is_instance_valid(_player):
		_player.set_physics_process(false)
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.set_physics_process(false)
	# Sweep in-flight projectiles — nothing keeps fighting behind the overlay.
	for p in get_tree().get_nodes_in_group("action_projectile"):
		p.queue_free()
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", color)
	for child in _overlay_vbox.get_children():
		if child != _overlay_title:
			child.queue_free()
			_overlay_vbox.remove_child(child)
	for b in buttons:
		_overlay_vbox.add_child(_overlay_button(str(b["label"]), b["cb"]))
	_overlay.visible = true


# --- Small builders --------------------------------------------------------

func _hud_label(text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := UiKit.label(text, size, color)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _make_bar(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.position = pos
	bg.size = size
	bg.color = Color(0.09, 0.11, 0.13, 0.92)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	var fill := ColorRect.new()
	fill.position = pos
	fill.size = size
	fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.set_meta("w", size.x)
	parent.add_child(fill)
	return fill


func _set_bar(fill: ColorRect, fraction: float) -> void:
	if fill != null:
		fill.size.x = float(fill.get_meta("w")) * clampf(fraction, 0.0, 1.0)


func _overlay_button(text: String, on_press: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(460, 44)
	btn.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(btn, UiKit.PANEL, UiKit.BORDER)
	btn.pressed.connect(on_press)
	return btn


# --- Input actions (registered at runtime so project.godot stays clean) -----

func _ensure_input_actions() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("dodge", [KEY_SPACE])
	_bind("spirit_attack", [KEY_J], [MOUSE_BUTTON_LEFT])
	_bind("focus", [KEY_K, KEY_SHIFT], [MOUSE_BUTTON_RIGHT])
	_bind("card_1", [KEY_1, KEY_KP_1])
	_bind("card_2", [KEY_2, KEY_KP_2])
	_bind("card_3", [KEY_3, KEY_KP_3])
	_bind("card_4", [KEY_4, KEY_KP_4])
	_bind("card_5", [KEY_5, KEY_KP_5])
	_bind("card_6", [KEY_6, KEY_KP_6])


func _bind(action: String, keys: Array, mouse_buttons: Array = []) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in mouse_buttons:
		var ev := InputEventMouseButton.new()
		ev.button_index = b
		InputMap.action_add_event(action, ev)

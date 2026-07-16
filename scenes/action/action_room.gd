extends Node2D
## Action Combat Arc — Phase A vertical slice.
##
## A top-down arena where you move, dodge, slow time to plan (focus), and fight
## one telegraphed enemy. Owns the FocusMeter + world `time_factor`, the HUD, and
## win/lose. Reachable from the main menu's dev entry. Everything here is a
## tunable prototype whose only job is to find the *feel* before loadouts, rooms,
## and boons hang off it (roadmap Phases B+).

const SpiritPlayer := preload("res://scenes/action/spirit_player.gd")
const ActionEnemy := preload("res://scenes/action/action_enemy.gd")

const VIEW := Vector2(1280, 720)
const ARENA := Rect2(70, 110, 1140, 500)  # play bounds within the view

var focus := FocusMeter.new()
var time_factor := 1.0                     # read by the enemy each physics frame

var _player = null
var _enemy = null
var _over := false

var _p_hp_fill: ColorRect
var _focus_fill: ColorRect
var _focus_label: Label
var _e_hp_fill: ColorRect
var _e_hp_box: Control
var _vignette: ColorRect
var _overlay: Control
var _overlay_title: Label


func _ready() -> void:
	_ensure_input_actions()
	_build_background()
	_spawn_actors()
	_build_hud()


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
	var wants: bool = Input.is_action_pressed("focus") and _player != null and not _player.is_dead()
	focus.update(delta, wants)
	time_factor = focus.time_factor()


func _process(_delta: float) -> void:
	_refresh_hud()


func _draw() -> void:
	# Arena floor over the background so nothing is ever the grey clear colour.
	draw_rect(ARENA, Color(0.06, 0.09, 0.12))
	draw_rect(ARENA, Color(0.18, 0.28, 0.32), false, 2.0)


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

	_player.died.connect(_on_player_died)
	_enemy.died.connect(_on_enemy_died)


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

	# Focus vignette (shown while focusing).
	_vignette = ColorRect.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.color = Color(0.18, 0.42, 0.68, 0.0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_vignette)

	# Player HP + focus (top-left).
	root.add_child(_hud_label("THE SPECTER", Vector2(28, 22), 16, UiKit.INK))
	_p_hp_fill = _make_bar(root, Vector2(28, 48), Vector2(320, 18), UiKit.DANGER.lerp(Color(0.9, 0.35, 0.4), 0.4))
	root.add_child(_hud_label("FOCUS", Vector2(28, 74), 12, UiKit.MUTED))
	_focus_fill = _make_bar(root, Vector2(90, 74), Vector2(258, 14), UiKit.AMBER)
	_focus_label = _hud_label("◊ FOCUS ◊", Vector2(0, 96), 13, Color(0.7, 0.9, 1.0))
	_focus_label.size.x = VIEW.x
	_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_label.visible = false
	root.add_child(_focus_label)

	# Enemy HP (top-centre).
	_e_hp_box = Control.new()
	_e_hp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_e_hp_box)
	var e_label := _hud_label("THE DROWNED ONE", Vector2(VIEW.x * 0.5 - 150, 22), 15, UiKit.DANGER)
	e_label.size.x = 300
	e_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_hp_box.add_child(e_label)
	_e_hp_fill = _make_bar(_e_hp_box, Vector2(VIEW.x * 0.5 - 150, 48), Vector2(300, 16), UiKit.DANGER)

	# Controls hint (bottom).
	var hint := _hud_label(
		"WASD / Arrows  move      SPACE  dodge      LMB / J  spirit bolt      RMB / K  focus (slow time)",
		Vector2(0, VIEW.y - 34), 13, UiKit.MUTED)
	hint.size.x = VIEW.x
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	# Win/lose overlay (hidden until the fight ends).
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
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.custom_minimum_size = Vector2(460, 0)
	center.add_child(vbox)
	_overlay_title = UiKit.label("", 24, UiKit.INK)
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_title.custom_minimum_size = Vector2(460, 0)
	_overlay_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_overlay_title)
	vbox.add_child(_overlay_button("Fight again", func() -> void: get_tree().reload_current_scene()))
	vbox.add_child(_overlay_button("Back to menu", func() -> void: SceneFlow.goto_main_menu()))


# --- HUD refresh -----------------------------------------------------------

func _refresh_hud() -> void:
	if _player != null and is_instance_valid(_player):
		_set_bar(_p_hp_fill, _player.hp / _player.max_hp)
	if _enemy != null and is_instance_valid(_enemy):
		_set_bar(_e_hp_fill, _enemy.hp / _enemy.max_hp)
	elif _e_hp_box != null:
		_e_hp_box.visible = false

	_set_bar(_focus_fill, focus.fraction())
	_focus_fill.color = UiKit.DANGER if focus.is_recharging() else (Color(0.55, 0.85, 1.0) if focus.active else UiKit.AMBER)
	_focus_label.visible = focus.active
	var target_a := 0.22 if focus.active else 0.0
	_vignette.color.a = lerpf(_vignette.color.a, target_a, 0.25)


# --- End state -------------------------------------------------------------

func _on_enemy_died() -> void:
	_end("The Drowned One is unmade.\nThe deep is quiet — for now.", UiKit.GOOD)


func _on_player_died() -> void:
	_end("You are dragged back into the dark.\nThe soul does not end — it only tries again.", UiKit.DANGER)


func _end(title: String, color: Color) -> void:
	if _over:
		return
	_over = true
	time_factor = 1.0
	_vignette.color.a = 0.0
	if _player != null and is_instance_valid(_player):
		_player.set_physics_process(false)
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.set_physics_process(false)
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", color)
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

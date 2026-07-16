extends Control
## The run map screen (Phase 5b): the hub of a life.
##
## Renders the current run's map (RunManager.current) as a left-to-right graph —
## entry on the left, boss on the right — and lets the player step to any node
## the current one connects to. A combat node hands off to the combat scene
## (which builds the fight from the run); everything else resolves inline (rest,
## finding an item, a small event) and the map refreshes. Presentation only: the
## rules live in RunState.

# Encounter glyph + accent colour by node type.
const TYPE_VISUAL := {
	"combat": ["⚔", Color(0.80, 0.40, 0.35)],
	"elite": ["✦", Color(0.88, 0.55, 0.32)],
	"boss": ["☠", Color(0.88, 0.33, 0.33)],
	"rest": ["❦", Color(0.55, 0.74, 0.55)],
	"item_search": ["?", Color(0.87, 0.64, 0.32)],
	"event": ["!", Color(0.62, 0.52, 0.78)],
	"shrine": ["✚", Color(0.50, 0.76, 0.78)],
	"merchant": ["$", Color(0.82, 0.72, 0.42)],
	"treasure": ["◆", Color(0.87, 0.70, 0.35)],
	"memory_anomaly": ["◈", Color(0.52, 0.74, 0.70)],
}

# Layout box for the map (base 1280x720; canvas_items stretch handles resizing).
const MAP_LEFT := 90.0
const MAP_RIGHT := 1190.0
const MAP_TOP := 150.0
const MAP_BOTTOM := 600.0

var _run: RunState
var _map_layer: Control
var _hp_label: Label
var _hint_label: Label
var _overlay: Control
var _positions: Dictionary = {}  # node id -> Vector2 center


func _ready() -> void:
	if ContentRegistry.ids_of("card").is_empty():
		ContentLoader.load_all(ContentRegistry)
	_run = RunManager.current
	_build_ui()
	if _run == null:
		_hint_label.text = "No run in progress."
		return
	_compute_positions()
	_draw_edges()
	_refresh()


# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------

func _on_node_clicked(node_id: String) -> void:
	if not _run.can_travel_to(node_id):
		return
	_run.travel_to(node_id)
	var node := _run.current_node()
	if RunCombat.is_combat_node(node.node_type):
		SceneFlow.goto_combat()  # the combat scene builds this fight from the run
		return
	_resolve_non_combat(node)
	_refresh()


func _resolve_non_combat(node: MapNode) -> void:
	match node.node_type:
		"rest":
			_heal_boon(int(_run.max_hp * 0.30), "A dry place to rest",
				"You bind your wounds and breathe. The tide waits.")
		"shrine":
			_heal_boon(int(_run.max_hp * 0.20), "A shrine to a drowned saint",
				"You leave an offering. The cold ache eases.")
		"memory_anomaly":
			_heal_boon(int(_run.max_hp * 0.12), "A place that should not be",
				"Something here almost remembers you. For a moment you feel whole.")
		"item_search", "treasure", "merchant":
			_open_item_pick(node)
		"event":
			_open_event(node)
		_:
			_show_overlay("The path", "Nothing stirs here.", [{"label": "Continue", "cb": Callable()}])


func _heal_boon(amount: int, title: String, flavour: String) -> void:
	_run.heal(amount)
	_show_overlay(title, "%s\n\nRecovered %d HP." % [flavour, amount], [{"label": "Continue", "cb": Callable()}])


func _open_item_pick(node: MapNode) -> void:
	var choices := _offered_items(node)
	if choices.is_empty():
		_show_overlay("Picked clean", "Whatever was here is long gone.", [{"label": "Continue", "cb": Callable()}])
		return
	var options: Array = []
	for item in choices:
		var it: ItemDefinition = item
		options.append({
			"label": "%s  (%s)" % [it.display_name, _item_grant_text(it)],
			"cb": func() -> void: _run.acquire_item(it),
		})
	options.append({"label": "Leave it", "cb": Callable()})
	_show_overlay("You search the tideline", "Take one — it joins your loadout if a slot is free.", options)


func _open_event(node: MapNode) -> void:
	var rng := RngStream.new(RunManager.encounter_seed(node.id))
	var item := _offered_items(node)
	var options: Array = [
		{"label": "Tend your wounds (+%d HP)" % int(_run.max_hp * 0.25),
			"cb": func() -> void: _run.heal(int(_run.max_hp * 0.25))},
	]
	if not item.is_empty():
		var it: ItemDefinition = item[0]
		options.append({"label": "Take the risk — grab the %s" % it.display_name,
			"cb": func() -> void: _run.acquire_item(it)})
	_show_overlay("An unquiet stretch of coast",
		"The wind carries a voice you almost know. Do you rest, or reach for what glints in the water?", options)


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _refresh() -> void:
	# Rebuild node buttons (their state changes as you travel); edges are static.
	for child in _map_layer.get_children():
		if child is Button:
			child.queue_free()
			_map_layer.remove_child(child)
	var available := {}
	for node in _run.available_next():
		available[node.id] = true
	for node in _run.map.all_nodes():
		_map_layer.add_child(_make_node_button(node, available.has(node.id)))
	_hp_label.text = "❤ %d / %d" % [_run.hp, _run.max_hp]
	_hint_label.text = "Choose your next step" if not _run.available_next().is_empty() else "The road ends here."


func _make_node_button(node: MapNode, is_available: bool) -> Button:
	var visual: Array = TYPE_VISUAL.get(node.node_type, ["•", UiKit.MUTED])
	var is_current := node.id == _run.current_node_id
	var is_visited := _run.visited.has(node.id)

	var btn := Button.new()
	btn.size = Vector2(74, 74)
	btn.position = _positions.get(node.id, Vector2.ZERO) - btn.size / 2.0
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = not is_available
	btn.tooltip_text = node.node_type.capitalize().replace("_", " ")

	var accent: Color = visual[1]
	var border := UiKit.AMBER if is_available else (accent if is_current else UiKit.BORDER)
	var bg := UiKit.PANEL_HI if (is_available or is_current) else UiKit.PANEL.darkened(0.15)
	UiKit.style_button(btn, bg, border, is_available or is_current)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	btn.add_child(box)
	var glyph := UiKit.label(str(visual[0]), 26, accent if not is_visited or is_available else accent.darkened(0.3))
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(glyph)
	if is_current:
		var here := UiKit.label("here", 9, UiKit.AMBER)
		here.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(here)
	UiKit.ignore_mouse(box)

	btn.pressed.connect(_on_node_clicked.bind(node.id))
	return btn


func _draw_edges() -> void:
	for node in _run.map.all_nodes():
		for nid in node.next_ids:
			if not _positions.has(nid):
				continue
			var line := Line2D.new()
			line.width = 3.0
			line.default_color = Color(0.28, 0.38, 0.40, 0.7)
			line.points = PackedVector2Array([_positions[node.id], _positions[nid]])
			_map_layer.add_child(line)


func _compute_positions() -> void:
	var map := _run.map
	var x_step := (MAP_RIGHT - MAP_LEFT) / maxf(1.0, float(map.rows - 1))
	var y_center := (MAP_TOP + MAP_BOTTOM) / 2.0
	var y_step := minf(96.0, (MAP_BOTTOM - MAP_TOP) / maxf(1.0, float(map.width - 1)))
	for node in map.all_nodes():
		var x := MAP_LEFT + node.row * x_step
		var y := y_center + (node.col - (map.width - 1) / 2.0) * y_step
		_positions[node.id] = Vector2(x, y)


# ---------------------------------------------------------------------------
# Reusable choice overlay
# ---------------------------------------------------------------------------

## Shows a modal with a title, message, and option buttons. Each option is
## {label, cb}; cb (may be an empty Callable) runs, then the overlay closes and
## the map refreshes.
func _show_overlay(title: String, message: String, options: Array) -> void:
	for child in _overlay.get_children():
		child.queue_free()
		_overlay.remove_child(child)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", UiKit.stylebox(UiKit.PANEL, UiKit.BORDER, 1, 10))
	center.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 28)
	panel.add_child(pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	pad.add_child(box)

	box.add_child(UiKit.label(title, 20, UiKit.INK))
	var msg := UiKit.label(message, 14, UiKit.MUTED)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(500, 0)
	box.add_child(msg)

	for option in options:
		var btn := Button.new()
		btn.text = str(option.get("label", "Continue"))
		btn.custom_minimum_size = Vector2(0, 42)
		btn.focus_mode = Control.FOCUS_NONE
		UiKit.style_button(btn, UiKit.PANEL_HI, UiKit.BORDER)
		var cb: Callable = option.get("cb", Callable())
		btn.pressed.connect(func() -> void:
			if cb.is_valid():
				cb.call()
			_overlay.visible = false
			_refresh())
		box.add_child(btn)

	_overlay.visible = true


# ---------------------------------------------------------------------------
# Content helpers
# ---------------------------------------------------------------------------

## Up to 3 universe items the player isn't already carrying, chosen by the
## node's deterministic seed.
func _offered_items(node: MapNode) -> Array:
	var universe = ContentRegistry.get_def("universe", _run.universe_id)
	if universe == null:
		return []
	var pool: Array = []
	for item_id in universe.item_ids:
		if not _run.inventory.has(item_id):
			var item = ContentRegistry.get_def("item", item_id)
			if item != null:
				pool.append(item)
	var rng := RngStream.new(RunManager.encounter_seed(node.id))
	rng.shuffle(pool)
	return pool.slice(0, mini(3, pool.size()))


func _item_grant_text(item: ItemDefinition) -> String:
	if item.granted_card_ids.is_empty():
		return "passive"
	var names: Array[String] = []
	for cid in item.granted_card_ids:
		var card = ContentRegistry.get_def("card", cid)
		names.append(card.display_name if card != null else cid)
	return ", ".join(names)


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	add_child(UiKit.background())

	_map_layer = Control.new()
	_map_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE  # buttons still get clicks
	add_child(_map_layer)

	# Top bar
	var top := HBoxContainer.new()
	top.position = Vector2(24, 22)
	top.custom_minimum_size = Vector2(1232, 0)
	top.add_theme_constant_override("separation", 16)
	add_child(top)
	var back := Button.new()
	back.text = "⟵ Abandon"
	back.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(back, UiKit.PANEL, UiKit.BORDER)
	back.pressed.connect(func() -> void:
		RunManager.end_run()
		SceneFlow.goto_main_menu())
	top.add_child(back)
	var title := UiKit.label("The Lovecraftian Coast — find your way to the light", 18, UiKit.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	_hp_label = UiKit.label("", 17, Color(0.85, 0.5, 0.5))
	top.add_child(_hp_label)

	# Bottom hint
	_hint_label = UiKit.label("", 14, UiKit.MUTED)
	_hint_label.position = Vector2(0, 660)
	_hint_label.custom_minimum_size = Vector2(1280, 0)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint_label)

	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)

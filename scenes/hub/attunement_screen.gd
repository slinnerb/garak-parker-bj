extends Control
## Attunement screen (Phase 4): choose which carried items to equip, and watch
## the combat deck rebuild in real time. This is the visible proof of the core
## rule — equipment and deckbuilding are two views of one system: toggling an
## item changes the slot count AND the deck preview together.
##
## Presentation only. The Inventory and Attunement domain objects hold the state
## and enforce the rules (slot budget, cursed items refusing removal); this
## screen renders them and forwards clicks. On "Begin the Fight" it stashes the
## chosen loadout in CombatRequest and enters combat.

const ENEMY_ID := "brine_soaked_villager"

var _inventory: Inventory
var _attunement: Attunement

var _item_grid: GridContainer
var _slots_label: Label
var _deck_list: VBoxContainer
var _hint_label: Label


func _ready() -> void:
	if ContentRegistry.ids_of("item").is_empty():
		ContentLoader.load_all(ContentRegistry)
	_inventory = CombatDemo.carried_inventory(ContentRegistry)
	_attunement = CombatDemo.default_attunement(ContentRegistry)
	_build_ui()
	_refresh()


# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------

func _on_item_clicked(item_id: String) -> void:
	var item := _inventory.get_item(item_id)
	if item == null:
		return
	if _attunement.is_attuned(item_id):
		if not _attunement.unattune(item_id):
			_flash("The %s will not come off." % item.display_name)
	elif not _attunement.attune(item):
		_flash("Not enough attunement slots for the %s (needs %d)." % [item.display_name, item.slot_cost])
	_refresh()


func _on_begin_pressed() -> void:
	var ids: Array = []
	for item in _attunement.attuned_items():
		ids.append(item.id)
	CombatRequest.set_request(CombatDemo.DEMO_ARCHETYPE, ids, ENEMY_ID)
	SceneFlow.goto_combat()


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _refresh() -> void:
	_refresh_items()
	_refresh_deck()
	_slots_label.text = "Attunement  %d / %d slots" % [_attunement.used_slots(), _attunement.capacity]


func _refresh_items() -> void:
	for child in _item_grid.get_children():
		child.queue_free()
		_item_grid.remove_child(child)
	for item in _inventory.all():
		_item_grid.add_child(_make_item_card(item))


func _make_item_card(item: ItemDefinition) -> Control:
	var attuned := _attunement.is_attuned(item.id)
	var can_add := _attunement.can_attune(item)
	var accent := UiKit.AMBER if attuned else UiKit.BORDER
	if item.cursed:
		accent = UiKit.DANGER if attuned else accent

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(232, 132)
	btn.focus_mode = Control.FOCUS_NONE
	# Everything is clickable (attuned -> try remove, unattuned -> try add); the
	# domain decides what's allowed and the hint explains any refusal.
	UiKit.style_button(btn, UiKit.PANEL_HI if attuned else UiKit.PANEL, accent, attuned)
	btn.pressed.connect(_on_item_clicked.bind(item.id))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12
	box.offset_top = 10
	box.offset_right = -12
	box.offset_bottom = -10
	btn.add_child(box)

	var header := HBoxContainer.new()
	var name_label := UiKit.label(item.display_name, 15, UiKit.INK)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	var badge := "ATTUNED" if attuned else ("+%d slot%s" % [item.slot_cost, "" if item.slot_cost == 1 else "s"])
	header.add_child(UiKit.label(badge, 11, UiKit.AMBER if attuned else UiKit.MUTED))
	box.add_child(header)

	var meta := item.category.capitalize()
	if item.cursed:
		meta += "  ·  cursed"
	box.add_child(UiKit.label(meta, 11, UiKit.DANGER if item.cursed else UiKit.MUTED))

	box.add_child(UiKit.label(_grants_text(item), 12, UiKit.MUTED))

	# A dim footer line telling the player what a click will do.
	var action := ""
	if attuned:
		action = "click: unattune" if item.removable else "cursed — cannot remove"
	elif can_add:
		action = "click: attune"
	else:
		action = "no free slots"
	var action_label := UiKit.label(action, 10, UiKit.MUTED.darkened(0.05))
	action_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	box.add_child(action_label)

	UiKit.ignore_mouse(box)
	return btn


func _grants_text(item: ItemDefinition) -> String:
	if item.granted_card_ids.is_empty():
		if not item.passive_modifiers.is_empty():
			return "Passive: strengthens other cards"
		return "Grants no cards"
	var names: Array[String] = []
	for card_id in item.granted_card_ids:
		var card = ContentRegistry.get_def("card", card_id)
		names.append(card.display_name if card != null else card_id)
	var prefix := "Cards: " if item.category != "consumable" else "Consumable (%d): " % maxi(1, item.charges)
	return prefix + ", ".join(names)


func _refresh_deck() -> void:
	for child in _deck_list.get_children():
		child.queue_free()
		_deck_list.remove_child(child)
	# Count duplicate cards so the preview reads "Harpoon Thrust ×2".
	var deck := _attunement.build_deck(ContentRegistry)
	var counts: Dictionary = {}
	var order: Array[String] = []
	for card in deck:
		var name := card.display_name()
		if not counts.has(name):
			counts[name] = 0
			order.append(name)
		counts[name] += 1
	_deck_list.add_child(UiKit.label("Deck — %d cards" % deck.size(), 15, UiKit.INK))
	if order.is_empty():
		_deck_list.add_child(UiKit.label("Attune an item to form a deck.", 12, UiKit.MUTED))
	for name in order:
		var count: int = counts[name]
		var text := name if count == 1 else "%s  ×%d" % [name, count]
		_deck_list.add_child(UiKit.label(text, 13, UiKit.MUTED))


func _flash(message: String) -> void:
	_hint_label.text = message


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	add_child(UiKit.background())

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 26)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# Header
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	var back := Button.new()
	back.text = "⟵ Menu"
	back.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(back, UiKit.PANEL, UiKit.BORDER)
	back.pressed.connect(func() -> void: SceneFlow.goto_main_menu())
	top.add_child(back)
	var title := UiKit.label("Attune your loadout — your gear is your deck", 19, UiKit.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	_slots_label = UiKit.label("", 14, UiKit.AMBER)
	top.add_child(_slots_label)

	var intro := UiKit.label("You carry more than you can wield at once. Attune what fits your slots — every attuned item adds its card(s) to the fight.", 13, UiKit.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	# Body: carried items (left) | deck preview (right)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)

	var items_scroll := ScrollContainer.new()
	items_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(items_scroll)
	_item_grid = GridContainer.new()
	_item_grid.columns = 3
	_item_grid.add_theme_constant_override("h_separation", 12)
	_item_grid.add_theme_constant_override("v_separation", 12)
	_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_scroll.add_child(_item_grid)

	var deck_panel := PanelContainer.new()
	deck_panel.custom_minimum_size = Vector2(320, 0)
	deck_panel.add_theme_stylebox_override("panel", UiKit.stylebox(Color(0.08, 0.10, 0.12), UiKit.BORDER))
	body.add_child(deck_panel)
	var deck_margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		deck_margin.add_theme_constant_override("margin_%s" % side, 16)
	deck_panel.add_child(deck_margin)
	_deck_list = VBoxContainer.new()
	_deck_list.add_theme_constant_override("separation", 6)
	deck_margin.add_child(_deck_list)

	# Footer: hint | begin
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	root.add_child(footer)
	_hint_label = UiKit.label("Click an item to attune or remove it.", 13, UiKit.MUTED)
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_hint_label)
	var begin := Button.new()
	begin.text = "Begin the Fight  ⟶"
	begin.custom_minimum_size = Vector2(200, 46)
	begin.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(begin, Color(0.16, 0.13, 0.08), UiKit.AMBER, true)
	begin.pressed.connect(_on_begin_pressed)
	footer.add_child(begin)

class_name BodyArchetypeDefinition
extends ContentDefinition
## Body archetype definition (TYPE_BODY_ARCHETYPE): the body a soul is born
## into at the start of a life — base stats plus the starting item loadout.
##
## The body is the mortal half of progression: everything here is lost at
## death (see docs/GAME_VISION.md). Starting items must actually fit the
## body's slots, so validation sums their slot costs against base_slots when
## a registry is available to resolve them.
##
## Pure data + validation: no autoloads, no nodes. The registry parameter may
## be null, in which case cross-reference checks are skipped.

var base_hp: int = 1
var base_energy: int = 1
var base_slots: int = 6
var starting_item_ids: Array[String] = []
var universe_availability: Array[String] = ["*"]


func type_name() -> String:
	return TYPE_BODY_ARCHETYPE


static func from_dict(d: Dictionary) -> BodyArchetypeDefinition:
	var def := BodyArchetypeDefinition.new()
	def._apply_base(d)
	def.base_hp = int(d.get("base_hp", 1))
	def.base_energy = int(d.get("base_energy", 1))
	def.base_slots = int(d.get("base_slots", 6))
	def.starting_item_ids = ContentDefinition.to_string_array(d.get("starting_item_ids", []))
	def.universe_availability = ContentDefinition.to_string_array(d.get("universe_availability", ["*"]))
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	if base_hp < 1:
		problems.append(_ctx("field 'base_hp' must be >= 1 (got %d)" % base_hp))
	if base_energy < 1:
		problems.append(_ctx("field 'base_energy' must be >= 1 (got %d)" % base_energy))
	if base_slots < 1 or base_slots > 12:
		problems.append(_ctx("field 'base_slots' must be between 1 and 12 (got %d)" % base_slots))
	# A body with nothing in its hands has no cards — every deck starts from
	# physical items (core design rule).
	if starting_item_ids.is_empty():
		problems.append(_ctx("field 'starting_item_ids' must contain at least one item"))
	# Reports empty entries (which _check_ref would skip) as well as unresolved
	# ids. An empty entry here would also silently disable the slot-budget check
	# below, so catching it is what keeps an over-budget loadout from passing.
	_check_id_list(registry, starting_item_ids, TYPE_ITEM, "starting_item_ids", problems)
	# Slot budget check is only meaningful when every item resolves; missing
	# refs are already reported above.
	if registry != null:
		var slot_sum := 0
		var all_resolved := true
		for item_id in starting_item_ids:
			var item: Variant = registry.get_def(TYPE_ITEM, item_id)
			if item == null:
				all_resolved = false
				break
			slot_sum += int(item.slot_cost)
		if all_resolved and slot_sum > base_slots:
			problems.append(_ctx("starting items need %d slots but the body has only %d" % [slot_sum, base_slots]))
	_check_universe_availability(registry, universe_availability, problems)
	return problems

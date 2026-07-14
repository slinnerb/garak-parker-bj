class_name LootTableDefinition
extends ContentDefinition
## A loot table: what an enemy / node can drop. Two lists share one entry
## shape: `entries` is a weighted pool (one roll picks among them, so weight is
## required), `guaranteed` always drops (weight is meaningless there and only
## checked if an author supplies one anyway).
##
## Entry shape (plain Dictionary — loot entries are simple enough that a nested
## definition class would be ceremony):
##   kind: "item" | "card" | "remembrance"
##   ref_id: item/card id (required for item and card; remembrance is the soul
##           currency, no ref)
##   weight: float > 0 (entries only)
##   min_amount / max_amount: int >= 1, max defaults to min
##
## Pure data + validation: the registry is a parameter and may be null (then
## cross-reference checks are skipped).

const ENTRY_KINDS := ["item", "card", "remembrance"]

var entries: Array[Dictionary] = []
var guaranteed: Array[Dictionary] = []


func type_name() -> String:
	return TYPE_LOOT_TABLE


static func from_dict(d: Dictionary) -> LootTableDefinition:
	var def := LootTableDefinition.new()
	def._apply_base(d)
	def.entries = ContentDefinition.to_dict_array(d.get("entries", []))
	def.guaranteed = ContentDefinition.to_dict_array(d.get("guaranteed", []))
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	# A loot table that can never drop anything is dead content.
	if entries.is_empty() and guaranteed.is_empty():
		problems.append(_ctx("loot table must define at least one entry (entries or guaranteed)"))
	for i in entries.size():
		_validate_entry(registry, entries[i], "entries#%d" % i, true, problems)
	for i in guaranteed.size():
		_validate_entry(registry, guaranteed[i], "guaranteed#%d" % i, false, problems)
	return problems


## Shared per-entry checks. `label` keeps every problem traceable to the exact
## entry. Value types are checked before coercion so malformed data reports
## instead of crashing.
func _validate_entry(registry, entry: Dictionary, label: String, require_weight: bool, problems: Array[String]) -> void:
	var kind := str(entry.get("kind", ""))
	_check_in_set(kind, ENTRY_KINDS, "%s.kind" % label, problems)

	# item/card entries drop a specific definition; remembrance is currency.
	if kind == "item" or kind == "card":
		var ref_id := str(entry.get("ref_id", ""))
		if ref_id.is_empty():
			problems.append(_ctx("%s requires 'ref_id' for kind '%s'" % [label, kind]))
		else:
			var ref_type := TYPE_ITEM if kind == "item" else TYPE_CARD
			_check_ref(registry, ref_type, ref_id, "%s.ref_id" % label, problems)

	if require_weight:
		var w = entry.get("weight", 0.0)
		if not (w is int or w is float) or float(w) <= 0.0:
			problems.append(_ctx("%s.weight must be a number > 0" % label))
	elif entry.has("weight"):
		# Guaranteed drops need no weight, but a present-yet-broken one is
		# still an authoring mistake worth reporting.
		var w = entry.get("weight")
		if not (w is int or w is float) or float(w) <= 0.0:
			problems.append(_ctx("%s.weight must be a number > 0 when present" % label))

	# Amounts must be real ints, not floats: a fractional value would truncate
	# here but ship raw in the stored entry, so a "1.9/1.2" pair passes this
	# check yet has max < min at roll time. Require int outright.
	var raw_min = entry.get("min_amount", 1)
	var min_amount := 1
	if raw_min is int and raw_min >= 1:
		min_amount = raw_min
	else:
		problems.append(_ctx("%s.min_amount must be an int >= 1" % label))
	var raw_max = entry.get("max_amount", min_amount)
	if not (raw_max is int):
		problems.append(_ctx("%s.max_amount must be an int >= min_amount" % label))
	elif raw_max < min_amount:
		problems.append(_ctx("%s.max_amount must be >= min_amount (%d)" % [label, min_amount]))

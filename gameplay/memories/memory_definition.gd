class_name MemoryDefinition
extends ContentDefinition
## Memory definition (TYPE_MEMORY): a fragment the soul carries between lives.
##
## Memory types: instinct (a reflex the new body doesn't understand), technique
## (a learned move), trauma (powerful but scarring — a trauma memory MUST carry
## a drawback; power always costs, per docs/GAME_VISION.md), and item (the soul
## remembers a physical thing well enough to find it again).
##
## Pure data + validation: no autoloads, no nodes. The registry parameter may
## be null, in which case cross-reference checks are skipped.

const MEMORY_TYPES := ["instinct", "technique", "trauma", "item"]

var memory_type: String = ""
var effect: Dictionary = {}
var drawback: Dictionary = {}
var source_universe_id: String = ""
var unlock_requirements: Dictionary = {}


func type_name() -> String:
	return TYPE_MEMORY


static func from_dict(d: Dictionary) -> MemoryDefinition:
	var def := MemoryDefinition.new()
	def._apply_base(d)
	def.memory_type = str(d.get("memory_type", ""))
	var effect_v: Variant = d.get("effect", {})
	def.effect = effect_v if effect_v is Dictionary else {}
	var drawback_v: Variant = d.get("drawback", {})
	def.drawback = drawback_v if drawback_v is Dictionary else {}
	def.source_universe_id = str(d.get("source_universe_id", ""))
	var reqs_v: Variant = d.get("unlock_requirements", {})
	def.unlock_requirements = reqs_v if reqs_v is Dictionary else {}
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	_check_in_set(memory_type, MEMORY_TYPES, "memory_type", problems)
	if effect.is_empty():
		problems.append(_ctx("required field 'effect' is empty"))
	# Core design rule: trauma memories are powerful WITH a cost, never free.
	if memory_type == "trauma" and drawback.is_empty():
		problems.append(_ctx("trauma memories require a non-empty 'drawback'"))
	_check_ref(registry, TYPE_UNIVERSE, source_universe_id, "source_universe_id", problems)
	# Item memories re-manifest a real item, so the effect must name one.
	if memory_type == "item":
		var item_id := str(effect.get("item_id", ""))
		if item_id.is_empty():
			problems.append(_ctx("item memories require 'effect.item_id'"))
		else:
			_check_ref(registry, TYPE_ITEM, item_id, "effect.item_id", problems)
	return problems

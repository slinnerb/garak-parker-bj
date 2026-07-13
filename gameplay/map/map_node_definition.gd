class_name MapNodeDefinition
extends ContentDefinition
## A map node archetype: what kind of stop a map location can be (combat,
## merchant, shrine, ...). Map generation places instances of these archetypes;
## the archetype itself carries only selection weight and presentation, not
## layout or connections (those belong to the generated map, not to content).
##
## Pure data + validation: the registry is a parameter and may be null (then
## cross-reference checks are skipped).

## Node types are a closed set — each needs engine support (a scene / handler),
## unlike content ids which are open.
const NODE_TYPES := ["combat", "elite", "boss", "item_search", "event", "merchant", "shrine", "rest", "tattoo", "memory_anomaly", "treasure", "story"]

var node_type: String = ""
## >= 0: zero is legal — it means "never randomly placed", for nodes that only
## appear at fixed map positions (e.g. the boss).
var base_weight: float = 1.0
var universe_availability: Array[String] = ["*"]
var icon_ref: String = ""


func type_name() -> String:
	return TYPE_MAP_NODE


static func from_dict(d: Dictionary) -> MapNodeDefinition:
	var def := MapNodeDefinition.new()
	def._apply_base(d)
	def.node_type = str(d.get("node_type", ""))
	def.base_weight = float(d.get("base_weight", 1.0))
	# Only override the ["*"] default when the key is present — a malformed
	# value coerces to [] and surfaces as a validation problem.
	if d.has("universe_availability"):
		def.universe_availability = ContentDefinition.to_string_array(d.get("universe_availability"))
	def.icon_ref = str(d.get("icon_ref", ""))
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	_check_in_set(node_type, NODE_TYPES, "node_type", problems)
	if base_weight < 0.0:
		problems.append(_ctx("field 'base_weight' must be >= 0 (got %s)" % base_weight))
	_check_universe_availability(registry, universe_availability, problems)
	return problems

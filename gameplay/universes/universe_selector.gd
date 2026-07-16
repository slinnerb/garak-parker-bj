class_name UniverseSelector
extends RefCounted
## Chooses the universe for the next life (Phase 6, master prompt §3).
##
## The first three lives are a scripted on-ramp: whatever universe claims
## fixed_order_position 1, 2, 3 (Lovecraft → Japanese → Norse in the shipped
## content). From life four onward selection is seeded weighted randomness:
##   - never the same universe twice in a row (when there's a choice),
##   - recently-visited universes are down-weighted by their recent_visit_penalty,
##   - unlock requirements must be met,
##   - the last death's cause tags multiply matching death_cause_weights
##     (the way you die pulls the soul toward certain shores).
## Pure and deterministic given (registry, profile, rng).


## Returns the universe id for the life about to begin.
static func select_next(registry, profile: Dictionary, rng: RngStream) -> String:
	var next_life := int(profile.get("life_count", 0)) + 1

	# Scripted opening: honour fixed_order_position for lives 1..3.
	for id in registry.ids_of(ContentDefinition.TYPE_UNIVERSE):
		var def = registry.get_def(ContentDefinition.TYPE_UNIVERSE, id)
		if def != null and def.fixed_order_position == next_life:
			return str(id)

	# Weighted random era.
	var history: Array = profile.get("universe_history", [])
	var previous := str(history.back()) if not history.is_empty() else ""
	var last_cause_tags: Array = profile.get("stats", {}).get("last_death_cause_tags", [])

	var candidates: Array = []
	var weights: Array = []
	for id in registry.ids_of(ContentDefinition.TYPE_UNIVERSE):
		var def = registry.get_def(ContentDefinition.TYPE_UNIVERSE, id)
		if def == null or not _unlock_met(def.unlock_requirements, profile):
			continue
		var weight := maxf(0.0, def.base_weight)
		# Recency: the more recently visited, the less it calls to the soul.
		var recency := _lives_since_visit(history, str(id))
		if recency == 1 or recency == 2:
			weight *= clampf(1.0 - def.recent_visit_penalty, 0.0, 1.0)
		# Death-cause pull: matching weights multiply.
		for tag in last_cause_tags:
			if def.death_cause_weights.has(tag):
				weight *= maxf(0.0, float(def.death_cause_weights[tag]))
		candidates.append(str(id))
		weights.append(weight)

	# Hard rule: no immediate repeat, provided there is any alternative.
	if candidates.size() > 1 and candidates.has(previous):
		var idx := candidates.find(previous)
		candidates.remove_at(idx)
		weights.remove_at(idx)

	var chosen = rng.pick_weighted(candidates, weights)
	if chosen != null:
		return str(chosen)
	# Degenerate fallback (nothing unlocked / all weights zero): repeat the
	# previous universe rather than fail the reincarnation.
	return previous if not previous.is_empty() else "lovecraft_coast"


## How many lives ago a universe was last visited (1 = the previous life);
## 0 when never visited.
static func _lives_since_visit(history: Array, universe_id: String) -> int:
	for i in range(history.size() - 1, -1, -1):
		if str(history[i]) == universe_id:
			return history.size() - i
	return 0


## Supported unlock requirement keys (closed set for now): min_deaths,
## min_soul_level, min_remembrance. Unknown keys fail closed — content asking
## for a gate we can't check stays locked rather than leaking early.
static func _unlock_met(requirements: Dictionary, profile: Dictionary) -> bool:
	for key in requirements:
		match str(key):
			"min_deaths":
				if int(profile.get("death_count", 0)) < int(requirements[key]):
					return false
			"min_soul_level":
				if int(profile.get("soul_level", 0)) < int(requirements[key]):
					return false
			"min_remembrance":
				if int(profile.get("remembrance", 0)) < int(requirements[key]):
					return false
			_:
				return false
	return true

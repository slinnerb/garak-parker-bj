class_name SoulProgression
extends RefCounted
## The soul's permanent progression rules (Phase 6) — pure functions over the
## profile dictionary (see SaveManager.default_data("profile")), so every rule is
## testable without touching the real save file. The `Soul` autoload wraps these
## with persistence.
##
## Design guardrails (docs/GAME_VISION.md): permanent progression grants options
## and adaptations, not raw stat inflation. Adaptations are data
## (DeathAdaptationDefinition) matched against the DeathReport.

const TATTOO_UNLOCK_DEATHS := 2


# ---------------------------------------------------------------------------
# Death → profile
# ---------------------------------------------------------------------------

## Applies a death to a profile (in place) and returns what happened:
##   { "remembrance_gained": int, "tattoo_just_unlocked": bool }
## `chosen_adaptation_id` may be "" (the player skipped / nothing eligible).
static func apply_death(profile: Dictionary, report: DeathReport, chosen_adaptation_id: String) -> Dictionary:
	profile["death_count"] = int(profile.get("death_count", 0)) + 1
	profile["remembrance"] = int(profile.get("remembrance", 0)) + report.remembrance

	if not chosen_adaptation_id.is_empty():
		var owned: Array = profile.get("adaptations", [])
		if not owned.has(chosen_adaptation_id):
			owned.append(chosen_adaptation_id)
		profile["adaptations"] = owned

	# The second death opens the Memory Tattoo system (master prompt §9).
	var tattoo_just_unlocked := false
	if not bool(profile.get("tattoo_system_unlocked", false)) and int(profile["death_count"]) >= TATTOO_UNLOCK_DEATHS:
		profile["tattoo_system_unlocked"] = true
		profile["tattoo_slots"] = maxi(1, int(profile.get("tattoo_slots", 0)))
		tattoo_just_unlocked = true

	# Remember how this life ended (drives universe death-cause weighting).
	var stats: Dictionary = profile.get("stats", {})
	stats["last_death_cause_tags"] = report.death_cause_tags.duplicate()
	stats["deaths_in_%s" % report.universe_id] = int(stats.get("deaths_in_%s" % report.universe_id, 0)) + 1
	profile["stats"] = stats

	return {
		"remembrance_gained": report.remembrance,
		"tattoo_just_unlocked": tattoo_just_unlocked,
	}


## Marks a new life begun in a universe: bumps the life count, appends to the
## visit history, and unlocks that universe (walking its shore is knowing it).
static func begin_life(profile: Dictionary, universe_id: String) -> void:
	profile["life_count"] = int(profile.get("life_count", 0)) + 1
	var history: Array = profile.get("universe_history", [])
	history.append(universe_id)
	profile["universe_history"] = history
	var unlocked: Array = profile.get("unlocked_universes", [])
	if not unlocked.has(universe_id):
		unlocked.append(universe_id)
	profile["unlocked_universes"] = unlocked


# ---------------------------------------------------------------------------
# Adaptation eligibility
# ---------------------------------------------------------------------------

## The adaptations this death makes available to choose from. A definition is
## eligible when EVERY populated trigger key matches the report (an adaptation
## with enemy_tags AND universe_ids demands both), and the soul doesn't already
## have it. Data-driven — no hard-coded branches per adaptation (§7).
static func eligible_adaptations(registry, report: DeathReport, owned: Array) -> Array:
	var out: Array = []
	for id in registry.ids_of(ContentDefinition.TYPE_ADAPTATION):
		if owned.has(id):
			continue
		var def = registry.get_def(ContentDefinition.TYPE_ADAPTATION, id)
		if def != null and _trigger_matches(def.trigger, report):
			out.append(def)
	return out


static func _trigger_matches(trigger: Dictionary, report: DeathReport) -> bool:
	var any_populated := false
	if _has_entries(trigger, "death_cause_tags"):
		any_populated = true
		if not _intersects(trigger["death_cause_tags"], report.death_cause_tags):
			return false
	if _has_entries(trigger, "enemy_tags"):
		any_populated = true
		# The killer's tags are part of death_cause_tags (plus derived causes),
		# so match enemy tags against the same set.
		if not _intersects(trigger["enemy_tags"], report.death_cause_tags):
			return false
	if _has_entries(trigger, "carried_item_tags"):
		any_populated = true
		if not _intersects(trigger["carried_item_tags"], report.carried_item_tags):
			return false
	if _has_entries(trigger, "universe_ids"):
		any_populated = true
		if not (trigger["universe_ids"] as Array).has(report.universe_id):
			return false
	return any_populated


static func _has_entries(d: Dictionary, key: String) -> bool:
	return d.get(key) is Array and not (d.get(key) as Array).is_empty()


static func _intersects(a: Array, b: Array) -> bool:
	for value in a:
		if b.has(value):
			return true
	return false


# ---------------------------------------------------------------------------
# Adaptations → combat strength
# ---------------------------------------------------------------------------

## Translates owned adaptations into the combat modifiers CombatState reads:
##   { "taken_vs_tags": {enemy_tag: multiplier},      # damage taken from tagged enemies
##     "bonus_vs_tags": {enemy_tag: multiplier} }     # damage dealt to tagged enemies
## e.g. gills (resist 25% vs drowned) -> taken_vs_tags["drowned"] = 0.75.
## Multiple adaptations touching the same tag multiply together.
static func combat_modifiers(registry, adaptation_ids: Array) -> Dictionary:
	var taken: Dictionary = {}
	var bonus: Dictionary = {}
	for id in adaptation_ids:
		var def = registry.get_def(ContentDefinition.TYPE_ADAPTATION, id)
		if def == null:
			continue
		_fold_effect(def.effect, taken, bonus)
	return {"taken_vs_tags": taken, "bonus_vs_tags": bonus}


static func _fold_effect(effect: Dictionary, taken: Dictionary, bonus: Dictionary) -> void:
	var tag := str(effect.get("enemy_tag", ""))
	if tag.is_empty():
		return  # damage_type-keyed effects wait for typed enemy attacks
	var pct := float(effect.get("amount", 0)) / 100.0
	match str(effect.get("kind", "")):
		"damage_resist_pct":
			taken[tag] = float(taken.get(tag, 1.0)) * maxf(0.0, 1.0 - pct)
		"damage_bonus_pct":
			bonus[tag] = float(bonus.get(tag, 1.0)) * (1.0 + pct)

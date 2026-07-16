extends Node
## Current-life orchestrator (autoload singleton: `RunManager`) — Phase 5.
##
## Holds the active RunState and starts new runs. Starting a run seeds the global
## RNG from the run seed, so the map, encounters, and combats for that life are
## all reproducible from one number (docs/DECISIONS.md, determinism). This is the
## home the CombatRequest hand-off was standing in for — combat and the map read
## the current run from here.

const DEFAULT_ARCHETYPE := "coastal_drifter"

var current: RunState = null
## The report of the death that just ended a run, for the Moment of Recall.
## Set by report_death(); cleared when the next life begins.
var last_death_report: DeathReport = null


## True while a run is in progress (started and not yet ended in death/victory).
func has_run() -> bool:
	return current != null and not current.is_over()


## The full soul-aware entry point for a brand-new life: selects the next
## universe (fixed order, then weighted), records the life on the profile, and
## starts the run with the soul's adaptations. Falls back to the first playable
## universe when the destined one has no content yet (the soul reaches for other
## shores, but the coast pulls it back — see docs/DECISIONS.md).
func begin_new_life(content) -> RunState:
	last_death_report = null  # the past life fades as the new one begins
	var seed_value := RNG.fresh_seed()
	var destined := Soul.select_next_universe(content, RngStream.new(seed_value))
	var playable := _playable_or_fallback(content, destined)
	Soul.begin_life(playable)
	var run := start_run(content, seed_value, playable, DEFAULT_ARCHETYPE, Soul.adaptations())
	run.destined_universe_id = destined
	if destined != playable:
		Log.info(Log.Cat.UNIVERSE, "Destined for %s, but it is not yet playable — the coast pulls the soul back" % destined)
	return run


func _playable_or_fallback(content, universe_id: String) -> String:
	var def = content.get_def("universe", universe_id)
	if def != null and def.playable:
		return universe_id
	for id in content.ids_of("universe"):
		var candidate = content.get_def("universe", id)
		if candidate != null and candidate.playable:
			return str(id)
	return universe_id  # nothing playable at all — content validation would have failed boot


## Begins a new life mechanically: seeds RNG, builds the body from the archetype
## (HP, slots, starting items attuned), and generates the map. Takes the soul's
## adaptations as data so tests never touch the real profile. Returns the RunState.
func start_run(content, run_seed: int, universe_id: String, archetype_id: String = DEFAULT_ARCHETYPE, adaptation_ids: Array = []) -> RunState:
	RNG.set_master_seed(run_seed)

	var archetype = content.get_def("body_archetype", archetype_id)
	var run := RunState.new()
	run.run_seed = run_seed
	run.universe_id = universe_id
	run.destined_universe_id = universe_id
	run.archetype_id = archetype_id
	run.adaptation_ids = adaptation_ids.duplicate()
	run.max_hp = int(archetype.base_hp) if archetype != null else 60
	run.hp = run.max_hp
	run.base_energy = int(archetype.base_energy) if archetype != null else 3
	run.slot_capacity = int(archetype.base_slots) if archetype != null else 6

	run.inventory = Inventory.new()
	run.attunement = Attunement.new(run.slot_capacity)
	if archetype != null:
		for item_id in archetype.starting_item_ids:
			var item: ItemDefinition = content.get_def("item", item_id)
			if item != null:
				run.inventory.add(item)
				run.attunement.attune(item)

	# Let the universe's authored map settings (floors/branches/guaranteed types)
	# drive generation; fall back to the generator defaults if none are declared.
	var universe = content.get_def("universe", universe_id)
	var map_settings: Dictionary = universe.map_gen_settings if universe != null and universe.map_gen_settings is Dictionary else {}
	run.map = MapGenerator.generate_from_settings(RNG.stream(RNG.MAP), map_settings)
	current = run
	Log.info(Log.Cat.RUN, "Run started: universe=%s seed=%d (%d map nodes)" % [
		universe_id, run_seed, run.map.all_nodes().size(),
	])
	EventBus.emit_signal("run_started", universe_id)
	return run


## Concludes a fatal run: builds the DeathReport (§7 steps 2-11) from the run
## that just ended and the enemy that ended it (may be null), stashes it for the
## Moment of Recall, and clears the body. The report is NOT yet applied to the
## profile — the recall screen does that once the player has chosen.
func report_death(killer: EnemyDefinition) -> DeathReport:
	if current == null:
		return null
	last_death_report = DeathReport.build(current, killer, Soul.life_count())
	Log.info(Log.Cat.DEATH, last_death_report.summary())
	end_run()
	return last_death_report


## Ends the current run (death or leaving). The permanent profile is untouched;
## the death path goes through report_death + the Moment of Recall.
func end_run() -> void:
	current = null


## A per-encounter RNG seed derived from the run seed and node, so a given fight
## in a given run always plays out the same way.
func encounter_seed(node_id: String) -> int:
	return hash("%d:%s" % [current.run_seed if current != null else 0, node_id])

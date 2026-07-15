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


## True while a run is in progress (started and not yet ended in death/victory).
func has_run() -> bool:
	return current != null and not current.is_over()


## Begins a new life: seeds RNG, builds the body from the archetype (HP, slots,
## starting items attuned), and generates the map. Returns the RunState.
func start_run(content, run_seed: int, universe_id: String, archetype_id: String = DEFAULT_ARCHETYPE) -> RunState:
	RNG.set_master_seed(run_seed)

	var archetype = content.get_def("body_archetype", archetype_id)
	var run := RunState.new()
	run.run_seed = run_seed
	run.universe_id = universe_id
	run.archetype_id = archetype_id
	run.max_hp = int(archetype.base_hp) if archetype != null else 60
	run.hp = run.max_hp
	run.slot_capacity = int(archetype.base_slots) if archetype != null else 6

	run.inventory = Inventory.new()
	run.attunement = Attunement.new(run.slot_capacity)
	if archetype != null:
		for item_id in archetype.starting_item_ids:
			var item: ItemDefinition = content.get_def("item", item_id)
			if item != null:
				run.inventory.add(item)
				run.attunement.attune(item)

	run.map = MapGenerator.generate(RNG.stream(RNG.MAP))
	current = run
	Log.info(Log.Cat.RUN, "Run started: universe=%s seed=%d (%d map nodes)" % [
		universe_id, run_seed, run.map.all_nodes().size(),
	])
	EventBus.emit_signal("run_started", universe_id)
	return run


## Ends the current run (death or leaving). The permanent profile is untouched;
## soul progression on death lands in Phase 6.
func end_run() -> void:
	current = null


## A per-encounter RNG seed derived from the run seed and node, so a given fight
## in a given run always plays out the same way.
func encounter_seed(node_id: String) -> int:
	return hash("%d:%s" % [current.run_seed if current != null else 0, node_id])

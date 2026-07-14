class_name Combatant
extends RefCounted
## Runtime combat state shared by the player and enemies (Phase 3 combat).
##
## A combatant is pure mutable state plus the small, rule-free mutations every
## fighter needs (take damage through block, gain block, heal, hold statuses).
## All the *rules* — damage modifiers, status hooks, decay, targeting — live in
## StatusEngine / EffectExecutor / CombatState, which read and drive this state.
## Keeping the combatant dumb is what makes those systems unit-testable in
## isolation (see docs/DECISIONS.md, combat architecture).
##
## `statuses` maps a status id to a positive stack count; an id at 0 stacks is
## erased, so `has_status` and truthiness stay simple.

var id: String = ""
var display_name: String = ""
var max_hp: int = 1
var hp: int = 1
## Temporary damage absorption, normally reset at the start of the owner's turn.
var block: int = 0
## status_id -> stacks (always > 0 while present).
var statuses: Dictionary = {}


func _init(combatant_id: String = "", name: String = "", maximum_hp: int = 1) -> void:
	id = combatant_id
	display_name = name
	max_hp = maxi(1, maximum_hp)
	hp = max_hp


func is_alive() -> bool:
	return hp > 0


## Adds block (never negative). Blocks past max are allowed — some effects stack.
func add_block(amount: int) -> void:
	if amount > 0:
		block += amount


## Block normally evaporates at the start of the owner's turn.
func reset_block() -> void:
	block = 0


## Heals up to max_hp. No-op on the dead (healing never revives). Returns HP gained.
func heal(amount: int) -> int:
	if amount <= 0 or not is_alive():
		return 0
	var before := hp
	hp = mini(max_hp, hp + amount)
	return hp - before


## Applies already-modified damage: block absorbs first, the remainder cuts HP.
## Returns HP actually lost (0 if fully blocked), which callers use for triggers.
func receive_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	var absorbed := mini(block, amount)
	block -= absorbed
	var to_hp := amount - absorbed
	hp = maxi(0, hp - to_hp)
	return to_hp


## Direct HP loss that ignores block — for damage-over-time (poison/burning),
## which by convention bypasses armor. Returns HP lost.
func lose_hp(amount: int) -> int:
	if amount <= 0:
		return 0
	var before := hp
	hp = maxi(0, hp - amount)
	return before - hp


func get_status(status_id: String) -> int:
	return int(statuses.get(status_id, 0))


func has_status(status_id: String) -> bool:
	return get_status(status_id) > 0


## Sets absolute stacks; <= 0 removes the status entirely.
func set_status(status_id: String, stacks: int) -> void:
	if stacks <= 0:
		statuses.erase(status_id)
	else:
		statuses[status_id] = stacks


## Adds (or subtracts) stacks, clamping removal at 0.
func add_status_stacks(status_id: String, delta: int) -> void:
	set_status(status_id, get_status(status_id) + delta)

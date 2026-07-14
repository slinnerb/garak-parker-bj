class_name EnemyState
extends Combatant
## An enemy's combat state (Phase 3 combat): a Combatant plus its telegraphed
## intent and the bookkeeping the intent AI needs (turns taken, per-intent use
## counts and cooldown clocks).
##
## Built from an EnemyDefinition; HP is rolled once at spawn within the def's
## variance using the enemy RNG stream so encounters stay reproducible. Intent
## *selection* lives in IntentSelector — this only holds the state it reads.

var definition: EnemyDefinition
## damage_type -> multiplier (> 0); types absent here take full damage.
var damage_taken_multipliers: Dictionary = {}
## The move telegraphed for this enemy's next turn (chosen by IntentSelector).
var current_intent: EnemyIntentDefinition = null
## How many turns this enemy has acted — drives first_turn / not_first_turn and
## serves as the clock for cooldown / max_uses conditions.
var turns_taken: int = 0

var _intent_use_counts: Dictionary = {}   # intent id -> times performed
var _intent_last_used: Dictionary = {}     # intent id -> turns_taken when last performed


func _init(enemy_def: EnemyDefinition = null, rolled_hp: int = 1) -> void:
	var did := enemy_def.id if enemy_def != null else ""
	var name := enemy_def.display_name if enemy_def != null else ""
	super(did, name, rolled_hp)
	definition = enemy_def
	if enemy_def != null:
		damage_taken_multipliers = enemy_def.damage_taken_multipliers


## Spawns an enemy from its definition, rolling HP within variance via `rng`.
static func from_definition(enemy_def: EnemyDefinition, rng: RngStream) -> EnemyState:
	var rolled := enemy_def.base_hp
	if enemy_def.hp_variance > 0:
		rolled += rng.randi_range(-enemy_def.hp_variance, enemy_def.hp_variance)
	return EnemyState.new(enemy_def, maxi(1, rolled))


## Damage-taken multiplier for a damage type (1.0 when unspecified).
func damage_multiplier(damage_type: String) -> float:
	return float(damage_taken_multipliers.get(damage_type, 1.0))


## Records that an intent was performed this turn (for cooldown / max_uses).
func record_intent_performed(intent_id: String) -> void:
	_intent_use_counts[intent_id] = int(_intent_use_counts.get(intent_id, 0)) + 1
	_intent_last_used[intent_id] = turns_taken


func intent_use_count(intent_id: String) -> int:
	return int(_intent_use_counts.get(intent_id, 0))


## Turns since an intent was last used, or -1 if never used.
func turns_since_intent(intent_id: String) -> int:
	if not _intent_last_used.has(intent_id):
		return -1
	return turns_taken - int(_intent_last_used[intent_id])

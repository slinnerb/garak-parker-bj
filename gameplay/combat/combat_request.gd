class_name CombatRequest
extends RefCounted
## A one-shot hand-off describing the fight to start (Phase 4).
##
## The attunement screen chooses a loadout and enemy, stashes it here, then
## changes to the combat scene, which reads it back. This is a deliberate
## stand-in: when run state (RunManager, Phases 5-6) exists it will own the
## current loadout and encounter, and this static hand-off goes away.

static var _pending: Dictionary = {}


## Records the fight to start next: which body archetype, which attuned item ids
## (in order), and which enemy.
static func set_request(archetype_id: String, attuned_item_ids: Array, enemy_id: String) -> void:
	_pending = {
		"archetype_id": archetype_id,
		"attuned_item_ids": attuned_item_ids.duplicate(),
		"enemy_id": enemy_id,
	}


## Returns the pending request and clears it (so a later direct scene load falls
## back to the default demo). Empty dictionary if none was set.
static func take() -> Dictionary:
	var request := _pending
	_pending = {}
	return request

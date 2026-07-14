extends RefCounted
## Sample status effect content (Phase 2).
##
## Ids are mechanic-neutral (exposed, weakened, ...) so every universe can
## reskin the same mechanics through display_name/description without new ids
## (see docs/CONTENT_SCHEMA.md). Hook payloads are open dictionaries the combat
## engine (Phase 3) interprets; the data model only guarantees their shape.


static func content_type() -> String:
	return "status"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "exposed",
			"display_name": "Exposed",
			"description": "Something has marked where the shell is thin. Damage taken is increased.",
			"tags": ["vulnerability"],
			"stacking": "intensity",
			"decay": "turn_end",
			"is_debuff": true,
			"hooks": {
				"on_take_damage": {"modifier": "incoming_damage_pct", "amount": 25},
			},
		},
		{
			"id": "weakened",
			"display_name": "Weakened",
			"description": "The arms remember drowning even if the mind does not. Damage dealt is reduced.",
			"tags": ["impairment"],
			"stacking": "intensity",
			"decay": "turn_end",
			"is_debuff": true,
			"hooks": {
				"on_deal_damage": {"modifier": "outgoing_damage_pct", "amount": -25},
			},
		},
		{
			"id": "burning",
			"display_name": "Burning",
			"description": "Lamp oil and salt burn with an unhealthy color. Takes fire damage at end of turn.",
			"tags": ["damage_over_time"],
			"stacking": "intensity",
			"decay": "turn_end",
			"is_debuff": true,
			"hooks": {
				"on_turn_end": {"action": "take_damage", "amount_per_stack": 1, "damage_type": "fire"},
			},
		},
		{
			"id": "hallucinating",
			"display_name": "Half-Heard Voices",
			"description": "The tide is speaking. It should not know your name. Junk cards seep into the deck.",
			"tags": ["mental"],
			"stacking": "duration",
			"decay": "turn_start",
			"is_debuff": true,
			"hooks": {
				"on_turn_start": {"action": "add_card", "card_id": "half_heard_whisper", "destination": "draw_pile"},
			},
		},
		{
			"id": "regeneration",
			"display_name": "Regeneration",
			"description": "The wounds close on their own, faster than they have any right to. Heals at end of turn.",
			"tags": ["recovery"],
			"stacking": "intensity",
			"decay": "turn_end",
			"is_debuff": false,
			"hooks": {
				"on_turn_end": {"action": "heal", "amount_per_stack": 1},
			},
		},
		{
			"id": "fortified",
			"display_name": "Fortified",
			"description": "Braced like a hull against the storm. Gains block at the start of each turn, fading by one each time.",
			"tags": ["defense"],
			"stacking": "intensity",
			# decay must match the hook phase (turn_start): the hook grants block at
			# turn start, then the stack fades. With decay turn_end the single stack
			# would be gone before the on_turn_start hook ever fired.
			"decay": "turn_start",
			"is_debuff": false,
			"hooks": {
				"on_turn_start": {"action": "gain_block", "amount_per_stack": 2},
			},
		},
	]
	return out

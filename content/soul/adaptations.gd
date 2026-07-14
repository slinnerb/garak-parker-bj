extends RefCounted
## Sample death adaptation content (Phase 2).
##
## Adaptations are permanent soul changes earned by dying a particular way —
## data, not hard-coded branches in the death manager (docs/CONTENT_SCHEMA.md).
## Drawbacks keep them from becoming raw power creep: the soul adapts, it does
## not simply improve (docs/GAME_VISION.md pillar 3).


static func content_type() -> String:
	return "adaptation"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "gills_that_should_not_be",
			"display_name": "Gills That Should Not Be",
			"description": "Three faint lines below each ear. A doctor would call them birthmarks. They open, very slightly, near deep water.",
			"tags": ["drowning"],
			"trigger": {"death_cause_tags": ["drowning"]},
			"effect": {"kind": "damage_resist_pct", "enemy_tag": "drowned", "amount": 25},
			"drawback": {"kind": "damage_taken_pct", "damage_type": "fire", "amount": 10},
			"unlock_requirements": {},
		},
		{
			"id": "eyes_adjusted_to_the_dark",
			"display_name": "Eyes Adjusted to the Dark",
			"description": "Having seen what waits outside once, the soul flinches less the second time. The trouble with eyes that have adjusted is that they keep seeing.",
			"tags": ["cosmic"],
			"trigger": {"death_cause_tags": ["cosmic"], "enemy_tags": ["cosmic"]},
			"effect": {"kind": "damage_resist_pct", "damage_type": "cosmic", "amount": 25},
			"drawback": {"kind": "awareness_delta", "amount": 1},
			"unlock_requirements": {},
		},
		{
			"id": "scar_of_the_first_light",
			"display_name": "Scar of the First Light",
			"description": "A pale band across the chest, exactly where the beam lingered. Great adversaries feel familiar now — and they seem to remember you too.",
			"tags": ["boss"],
			"trigger": {"enemy_tags": ["boss"], "universe_ids": ["lovecraft_coast"]},
			"effect": {"kind": "damage_bonus_pct", "enemy_tag": "boss", "amount": 10},
			"drawback": {"kind": "recognized_by_bosses", "dialogue_flag": "boss_recognition"},
			"unlock_requirements": {},
		},
	]
	return out

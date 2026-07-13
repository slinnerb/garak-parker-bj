extends RefCounted
## Sample difficulty tier content (Phase 2).
##
## Harder tiers scale enemies up and pay out more remembrance — per the soul
## progression pillar, difficulty buys the player options and currency, never
## raw power (docs/GAME_VISION.md).


static func content_type() -> String:
	return "difficulty"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "standard",
			"display_name": "Standard",
			"description": "The lives as they are meant to be lived, and lost.",
			"enemy_hp_multiplier": 1.0,
			"enemy_damage_multiplier": 1.0,
			"remembrance_multiplier": 1.0,
			"unlock_requirements": {},
		},
		{
			"id": "drowned",
			"display_name": "Drowned",
			"description": "The water is higher this time. The soul remembers more of what it costs.",
			"enemy_hp_multiplier": 1.3,
			"enemy_damage_multiplier": 1.25,
			"remembrance_multiplier": 1.5,
			"unlock_requirements": {"min_deaths": 5},
		},
	]
	return out

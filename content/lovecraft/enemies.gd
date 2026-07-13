extends RefCounted
## Sample enemy content for the Lovecraftian Coast (Phase 2).
##
## Three normal enemies, one elite, one boss — the vertical slice roster
## (master prompt section 19). Telegraphs are restrained horror: wrongness,
## not tentacle spam (docs/GAME_VISION.md pillar 4). Every enemy keeps at
## least one unconditional intent so it always has a legal move.


static func content_type() -> String:
	return "enemy"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "brine_soaked_villager",
			"display_name": "Brine-Soaked Villager",
			"description": "He still wears his church clothes. He has been in the water for a long time, and he walked out of it anyway.",
			"tags": ["human", "drowned"],
			"base_hp": 26,
			"hp_variance": 3,
			"intents": [
				{
					"id": "clutch",
					"kind": "attack",
					"amount": 5,
					"weight": 3.0,
					"telegraph": "He reaches out as if he knows you.",
				},
				{
					"id": "waterlogged_wail",
					"kind": "debuff",
					"status_id": "weakened",
					"weight": 2.0,
					"telegraph": "Water spills from his mouth when he tries to speak.",
					"conditions": {"cooldown": 2},
				},
				{
					"id": "stagger_back",
					"kind": "defend",
					"amount": 4,
					"weight": 1.5,
					"telegraph": "He sways, hands over his face, apologizing to someone.",
				},
			],
			"behavior": "weighted_random",
			"loot_table_id": "loot_coast_normal",
			"universe_availability": ["lovecraft_coast"],
		},
		{
			"id": "pale_fisherman",
			"display_name": "Pale Fisherman",
			"description": "His catch has been good all season. Nobody asks what he uses for bait anymore.",
			"tags": ["human", "cultist"],
			"base_hp": 32,
			"hp_variance": 4,
			"intents": [
				{
					"id": "gutting_knife",
					"kind": "attack",
					"amount": 7,
					"weight": 3.0,
					"telegraph": "The knife is for fish. He looks at you anyway.",
				},
				{
					"id": "cast_the_net",
					"kind": "debuff",
					"status_id": "exposed",
					"weight": 2.0,
					"telegraph": "He gathers the net with a patience that has nothing to do with fish.",
					"conditions": {"cooldown": 2},
				},
				{
					"id": "mend_the_line",
					"kind": "defend",
					"amount": 5,
					"weight": 1.5,
					"telegraph": "He tends his line, unhurried, as if you were already caught.",
					"conditions": {"below_hp_pct": 0.5},
				},
			],
			"behavior": "weighted_random",
			"loot_table_id": "loot_coast_normal",
			"universe_availability": ["lovecraft_coast"],
		},
		{
			"id": "choir_of_the_shallows",
			"display_name": "Choir of the Shallows",
			"description": "Six kneeling shapes at the tideline, singing in perfect unison. There are five of them.",
			"tags": ["cultist", "cosmic"],
			"base_hp": 22,
			"hp_variance": 2,
			"damage_taken_multipliers": {"fire": 1.5},
			"intents": [
				{
					"id": "drone",
					"kind": "attack",
					"amount": 3,
					"times": 2,
					"weight": 3.0,
					"telegraph": "The hum settles into your teeth.",
				},
				{
					"id": "swelling_harmony",
					"kind": "buff",
					"status_id": "fortified",
					"weight": 1.5,
					"telegraph": "The voices agree on something.",
					"conditions": {"cooldown": 2},
				},
				{
					"id": "crescendo",
					"kind": "attack",
					"amount": 8,
					"weight": 1.0,
					"telegraph": "Every mouth opens at once. One of them is yours.",
					"conditions": {"not_first_turn": true},
				},
			],
			"behavior": "weighted_random",
			"loot_table_id": "loot_coast_normal",
			"universe_availability": ["lovecraft_coast"],
		},
		{
			"id": "tide_warden",
			"display_name": "Tide Warden",
			"description": "It stands where the harbor master used to stand, wearing the harbor master's coat. The coat fits it badly, and the tide obeys it well.",
			"tags": ["deep", "elite"],
			"base_hp": 58,
			"hp_variance": 5,
			"damage_taken_multipliers": {"fire": 1.25, "frost": 0.75},
			"intents": [
				{
					"id": "harpoon_lash",
					"kind": "attack",
					"amount": 9,
					"weight": 3.0,
					"telegraph": "It hefts a harpoon you would swear you have held.",
				},
				{
					"id": "drag_below",
					"kind": "debuff",
					"status_id": "exposed",
					"weight": 2.0,
					"telegraph": "The water rises around your ankles. It is not the tide.",
					"conditions": {"cooldown": 2},
				},
				{
					"id": "salt_scab",
					"kind": "defend",
					"amount": 8,
					"weight": 1.5,
					"telegraph": "Its hide crusts over, white and glistening.",
				},
				{
					"id": "breach",
					"kind": "attack",
					"amount": 6,
					"times": 2,
					"weight": 2.0,
					"telegraph": "The surface bulges before it moves.",
					"conditions": {"below_hp_pct": 0.5},
				},
			],
			"behavior": "weighted_random",
			"loot_table_id": "loot_coast_elite",
			"universe_availability": ["lovecraft_coast"],
			"is_elite": true,
		},
		{
			"id": "lighthouse_keeper",
			"display_name": "The Lighthouse Keeper",
			"description": "The light has not gone out in forty years. The keeper has not come down in forty years. The town is grateful, and does not finish the thought.",
			"tags": ["boss", "cosmic"],
			"base_hp": 110,
			"hp_variance": 6,
			"damage_taken_multipliers": {"cosmic": 0.5},
			"intents": [
				{
					"id": "sweep_of_the_beam",
					"kind": "attack",
					"amount": 7,
					"weight": 3.0,
					"telegraph": "The light passes over you, and it lingers.",
				},
				{
					"id": "lamp_goes_dark",
					"kind": "debuff",
					"status_id": "hallucinating",
					"weight": 2.0,
					"telegraph": "The lamp goes out. Something else keeps shining.",
					"conditions": {"cooldown": 3},
				},
				{
					"id": "mend_the_lens",
					"kind": "defend",
					"amount": 12,
					"weight": 1.5,
					"telegraph": "He turns to the lens with terrible tenderness.",
					"conditions": {"below_hp_pct": 0.5},
				},
				{
					"id": "what_the_light_found",
					"kind": "attack",
					"amount": 5,
					"times": 3,
					"weight": 2.0,
					"telegraph": "He recites everything the beam has ever touched. You are in the list twice.",
					"conditions": {"not_first_turn": true},
				},
			],
			"behavior": "weighted_random",
			"loot_table_id": "loot_coast_boss",
			"universe_availability": ["lovecraft_coast"],
			"is_boss": true,
		},
	]
	return out

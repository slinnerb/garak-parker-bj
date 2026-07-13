extends RefCounted
## Sample universe content (Phase 2): the fixed three-life on-ramp.
##
## Life one (lovecraft_coast) is the vertical slice and carries real content
## lists; lives two and three are declared so the reincarnation order, unlock
## flow, and save data have stable ids to point at, but stay unplayable until
## their content lands (docs/GAME_VISION.md).


static func content_type() -> String:
	return "universe"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "lovecraft_coast",
			"display_name": "The Drowning Coast",
			"description": "A failing fishing town on a coast the sea is slowly taking back.",
			"intro_text": "You wake with salt in your mouth and a name you answer to without recognizing it. The town below the cliff is half underwater at high tide. Nobody talks about it.",
			"tags": ["intro"],
			"theme_tags": ["coastal", "flooded", "cult", "cosmic"],
			"enemy_ids": ["brine_soaked_villager", "pale_fisherman", "choir_of_the_shallows"],
			"elite_ids": ["tide_warden"],
			"boss_ids": ["lighthouse_keeper"],
			"item_ids": [
				"rusted_harpoon",
				"oilskin_coat",
				"storm_lantern",
				"fishermans_gaff",
				"barnacle_crusted_shield",
				"tincture_of_salt",
				"signal_flare",
				"net_of_woven_hair",
				"whale_ivory_charm",
				"abyssal_fishhook",
				"drowned_mans_journal",
				"weeping_figurehead",
				"heart_of_the_reef",
			],
			# Accepted but not ref-checked until the event system lands (Phase 5).
			"event_ids": ["event_the_empty_chapel", "event_wrong_reflection"],
			"card_theme": "coastal_horror",
			"music_refs": ["music/coast_ambient", "music/coast_combat"],
			"difficulty_min": 1,
			"difficulty_max": 2,
			"unlock_requirements": {},
			"base_weight": 1.0,
			"recent_visit_penalty": 0.5,
			"death_cause_weights": {"drowning": 2.0, "cosmic": 1.5},
			"tattoo_weights": {"drowned_eye": 1.5, "broken_blade": 1.0},
			"awareness_modifier": 0.0,
			"map_gen_settings": {
				"floors": 8,
				"branches": 2,
				"guaranteed_node_types": ["item_search", "event", "rest", "elite", "boss"],
			},
			"fixed_order_position": 1,
			"playable": true,
		},
		{
			"id": "japanese_mythos",
			"display_name": "The Haunted Provinces",
			"description": "A feudal region where the shrines are cursed and the forests keep what wanders in.",
			"intro_text": "You wake on a road between rice fields, wearing sandals worn to the shape of your feet. A shrine gate stands ahead. Its symbol is one you have seen before, somewhere with more salt.",
			"tags": ["intro"],
			"theme_tags": ["feudal", "yokai", "haunted", "cosmic"],
			"enemy_ids": [],
			"elite_ids": [],
			"boss_ids": [],
			"item_ids": [],
			"event_ids": [],
			"card_theme": "folklore_horror",
			"music_refs": [],
			"difficulty_min": 1,
			"difficulty_max": 2,
			"unlock_requirements": {"min_deaths": 1},
			"base_weight": 1.0,
			"recent_visit_penalty": 0.5,
			"death_cause_weights": {},
			"tattoo_weights": {},
			"awareness_modifier": 0.0,
			"map_gen_settings": {},
			"fixed_order_position": 2,
			"playable": false,
		},
		{
			"id": "norse_mythos",
			"display_name": "The Corrupted Ragnarok",
			"description": "A frozen world ending incorrectly, where fate itself has stopped keeping its promises.",
			"intro_text": "You wake in snow that does not melt against your skin. Somewhere above the clouds, something enormous is wounded — the same wound you saw on a god with a different name.",
			"tags": ["intro"],
			"theme_tags": ["frozen", "ragnarok", "runes", "cosmic"],
			"enemy_ids": [],
			"elite_ids": [],
			"boss_ids": [],
			"item_ids": [],
			"event_ids": [],
			"card_theme": "frozen_myth",
			"music_refs": [],
			"difficulty_min": 1,
			"difficulty_max": 3,
			"unlock_requirements": {"min_deaths": 2},
			"base_weight": 1.0,
			"recent_visit_penalty": 0.5,
			"death_cause_weights": {},
			"tattoo_weights": {},
			"awareness_modifier": 0.0,
			"map_gen_settings": {},
			"fixed_order_position": 3,
			"playable": false,
		},
	]
	return out

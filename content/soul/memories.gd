extends RefCounted
## Sample soul memory content (Phase 2).
##
## Memories are fragments the soul carries between lives: instinct (a reflex
## the new body doesn't understand), technique (a learned move), trauma
## (powerful WITH a cost — never free, per docs/GAME_VISION.md), and item
## (the soul remembers a physical thing well enough to find it again).
## Effect/drawback payloads are open dictionaries interpreted by the
## reincarnation system when it lands.


static func content_type() -> String:
	return "memory"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "flinch_from_deep_water",
			"display_name": "Flinch From Deep Water",
			"description": "The new body has never seen the sea. It refuses to turn its back on any body of water deeper than a bath, and it is right not to.",
			"tags": ["instinct"],
			"memory_type": "instinct",
			"effect": {"kind": "start_combat_block", "amount": 3},
			"source_universe_id": "lovecraft_coast",
			"unlock_requirements": {},
		},
		{
			"id": "harpooners_cadence",
			"display_name": "Harpooner's Cadence",
			"description": "Brace, breathe, throw on the exhale. Nobody taught these hands that rhythm. They keep it anyway.",
			"tags": ["technique", "weapon"],
			"memory_type": "technique",
			"effect": {"kind": "card_damage_bonus", "card_tag": "weapon", "amount": 1},
			"source_universe_id": "lovecraft_coast",
			"unlock_requirements": {},
		},
		{
			"id": "the_water_closing_over",
			"display_name": "The Water Closing Over",
			"description": "When everything narrows, the body finds a strength it should not have — the strength of the moment before the end. It costs to carry that moment.",
			"tags": ["trauma"],
			"memory_type": "trauma",
			"effect": {"kind": "bonus_energy_below_half_hp", "amount": 1},
			"drawback": {"kind": "start_combat_status", "status_id": "weakened", "stacks": 1},
			"source_universe_id": "lovecraft_coast",
			"unlock_requirements": {"death_cause_tag": "drowning"},
		},
		{
			"id": "the_harpoon_remembered",
			"display_name": "The Harpoon, Remembered",
			"description": "The soul knows the weight of it, the pitting of the rust, the letters the flakes made. In every life, one turns up nearby.",
			"tags": ["item", "weapon"],
			"memory_type": "item",
			"effect": {"item_id": "rusted_harpoon"},
			"source_universe_id": "lovecraft_coast",
			"unlock_requirements": {},
		},
	]
	return out

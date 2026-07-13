extends RefCounted
## Sample body archetype content (Phase 2).
##
## The body is the mortal half of progression: these stats and the starting
## loadout are lost at death (docs/GAME_VISION.md). Starting items must fit
## the slot budget — validation sums their slot costs against base_slots.


static func content_type() -> String:
	return "body_archetype"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "coastal_drifter",
			"display_name": "Coastal Drifter",
			"description": "Nobody in the harbor town remembers hiring you, but everyone assumes somebody did. Your hands already know the work.",
			"tags": ["starter"],
			"base_hp": 70,
			"base_energy": 3,
			"base_slots": 6,
			# Slot costs: harpoon 1 + coat 1 + lantern 1 = 3 of 6.
			"starting_item_ids": ["rusted_harpoon", "oilskin_coat", "storm_lantern"],
			"universe_availability": ["lovecraft_coast"],
		},
	]
	return out

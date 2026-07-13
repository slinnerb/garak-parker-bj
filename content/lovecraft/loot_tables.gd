extends RefCounted
## Sample loot table content for the Lovecraftian Coast (Phase 2).
##
## One table per encounter tier. `entries` is a weighted pool; `guaranteed`
## always drops. Remembrance is the soul currency — every fight pays at least
## a little of it, because every death must teach the next life something
## (docs/GAME_VISION.md).


static func content_type() -> String:
	return "loot_table"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "loot_coast_normal",
			"display_name": "Coast Salvage",
			"description": "What the drowned and the desperate leave behind.",
			"entries": [
				{"kind": "item", "ref_id": "fishermans_gaff", "weight": 2.0},
				{"kind": "item", "ref_id": "tincture_of_salt", "weight": 2.0},
				{"kind": "item", "ref_id": "signal_flare", "weight": 1.5},
				{"kind": "item", "ref_id": "net_of_woven_hair", "weight": 1.0},
				{"kind": "remembrance", "weight": 1.0, "min_amount": 1, "max_amount": 2},
			],
			"guaranteed": [
				{"kind": "remembrance", "min_amount": 1, "max_amount": 2},
			],
		},
		{
			"id": "loot_coast_elite",
			"display_name": "Warden's Hoard",
			"description": "Things gathered from forty years of wrecks, sorted with inhuman care.",
			"entries": [
				{"kind": "item", "ref_id": "barnacle_crusted_shield", "weight": 1.5},
				{"kind": "item", "ref_id": "whale_ivory_charm", "weight": 1.5},
				{"kind": "item", "ref_id": "abyssal_fishhook", "weight": 1.0},
				{"kind": "item", "ref_id": "drowned_mans_journal", "weight": 0.5},
			],
			"guaranteed": [
				{"kind": "remembrance", "min_amount": 2, "max_amount": 4},
			],
		},
		{
			"id": "loot_coast_boss",
			"display_name": "The Keeper's Effects",
			"description": "What remains at the top of the lighthouse, where nobody has climbed in forty years.",
			"entries": [
				{"kind": "item", "ref_id": "heart_of_the_reef", "weight": 1.0},
				{"kind": "item", "ref_id": "drowned_mans_journal", "weight": 1.0},
				{"kind": "item", "ref_id": "weeping_figurehead", "weight": 0.75},
			],
			"guaranteed": [
				{"kind": "remembrance", "min_amount": 5, "max_amount": 8},
			],
		},
	]
	return out

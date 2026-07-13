extends RefCounted
## Sample item content for the Lovecraftian Coast (Phase 2).
##
## Items are the heart of the deck: every real card is granted by one of these
## physical things (docs/GAME_VISION.md pillar 2). granted_card_ids and the
## cards' source_item_id must stay bidirectional — validation checks both ends.
##
## Covers the vertical slice checklist (master prompt section 19): basic
## weapon, defensive item, utility tool, consumables, healing item, forbidden
## artifact, cursed item, rare item, multi-card item, and a passive relic.


static func content_type() -> String:
	return "item"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			# Basic weapon (starting loadout).
			"id": "rusted_harpoon",
			"display_name": "Rusted Harpoon",
			"description": "Salvaged from a boat that never came back. The rust flakes off in shapes like letters.",
			"tags": ["weapon", "starter"],
			"category": "weapon",
			"slot_cost": 1,
			"granted_card_ids": ["harpoon_thrust"],
			"rarity": "starter",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/rusted_harpoon",
		},
		{
			# Defensive item (starting loadout).
			"id": "oilskin_coat",
			"display_name": "Oilskin Coat",
			"description": "Keeps the rain out. Keeps other things out too, though nobody told you that when they gave it to you.",
			"tags": ["defensive", "starter"],
			"category": "defensive",
			"slot_cost": 1,
			"granted_card_ids": ["brace_the_hull"],
			"rarity": "starter",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/oilskin_coat",
		},
		{
			# Utility tool (starting loadout).
			"id": "storm_lantern",
			"display_name": "Storm Lantern",
			"description": "The flame leans toward the sea no matter which way the wind blows.",
			"tags": ["tool", "starter", "light"],
			"category": "tool",
			"slot_cost": 1,
			"granted_card_ids": ["lantern_sweep"],
			"rarity": "starter",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/storm_lantern",
		},
		{
			"id": "fishermans_gaff",
			"display_name": "Fisherman's Gaff",
			"description": "A hook for landing what the nets bring up. The last owner filed the point sharper than any fish requires.",
			"tags": ["weapon"],
			"category": "weapon",
			"slot_cost": 1,
			"granted_card_ids": ["gaff_hook"],
			"rarity": "common",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/fishermans_gaff",
		},
		{
			"id": "barnacle_crusted_shield",
			"display_name": "Barnacle-Crusted Shield",
			"description": "Pulled from the shallows. The barnacles are still alive, and they hold on tighter when the blows come.",
			"tags": ["defensive"],
			"category": "defensive",
			"slot_cost": 2,
			"granted_card_ids": ["shield_wall"],
			"rarity": "common",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/barnacle_crusted_shield",
		},
		{
			# Healing consumable.
			"id": "tincture_of_salt",
			"display_name": "Tincture of Salt",
			"description": "The apothecary swears by it. The apothecary also has not blinked in a while.",
			"tags": ["consumable", "healing"],
			"category": "consumable",
			"slot_cost": 1,
			"granted_card_ids": ["swallow_tincture"],
			"charges": 2,
			"rarity": "common",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/tincture_of_salt",
		},
		{
			# Offensive consumable.
			"id": "signal_flare",
			"display_name": "Signal Flare",
			"description": "For calling help from ships. No ship has answered one in years, but other things notice the light.",
			"tags": ["consumable", "fire"],
			"category": "consumable",
			"slot_cost": 1,
			"granted_card_ids": ["flare_burst"],
			"charges": 1,
			"rarity": "common",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/signal_flare",
		},
		{
			"id": "net_of_woven_hair",
			"display_name": "Net of Woven Hair",
			"description": "Too fine for fish. Whoever made it was catching something that struggles differently.",
			"tags": ["tool"],
			"category": "tool",
			"slot_cost": 1,
			"granted_card_ids": ["weighted_net"],
			"rarity": "uncommon",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/net_of_woven_hair",
		},
		{
			"id": "whale_ivory_charm",
			"display_name": "Whale-Ivory Charm",
			"description": "Carved with a symbol the carver's granddaughter says came to him in a dream. You have seen it somewhere before.",
			"tags": ["charm"],
			"category": "charm",
			"slot_cost": 1,
			"granted_card_ids": ["murmured_ward"],
			"rarity": "uncommon",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/whale_ivory_charm",
		},
		{
			# Rare weapon; its card exercises the repeat container effect.
			"id": "abyssal_fishhook",
			"display_name": "Abyssal Fishhook",
			"description": "Far too large for any boat in the harbor. Something used it to fish. It was not fishing for fish.",
			"tags": ["weapon", "deep"],
			"category": "weapon",
			"slot_cost": 1,
			"granted_card_ids": ["cast_beyond"],
			"rarity": "rare",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/abyssal_fishhook",
		},
		{
			# Forbidden artifact granting multiple cards.
			"id": "drowned_mans_journal",
			"display_name": "Drowned Man's Journal",
			"description": "The pages are dry. The ink is not. The handwriting in the later entries is yours.",
			"tags": ["forbidden", "knowledge"],
			"category": "forbidden",
			"slot_cost": 1,
			"granted_card_ids": ["forbidden_passage", "whispered_names"],
			"rarity": "rare",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/drowned_mans_journal",
		},
		{
			# Cursed item: powerful card bundled with a curse, and it will not let go.
			"id": "weeping_figurehead",
			"display_name": "Weeping Figurehead",
			"description": "A ship's figurehead the size of a forearm. It is always damp. You have stopped trying to put it down.",
			"tags": ["cursed", "deep"],
			"category": "charm",
			"slot_cost": 1,
			"granted_card_ids": ["siren_lament", "dirge_of_the_drowned"],
			"cursed": true,
			"removable": false,
			"rarity": "special",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/weeping_figurehead",
		},
		{
			# Passive relic: modifies other cards, grants none of its own.
			"id": "heart_of_the_reef",
			"display_name": "Heart of the Reef",
			"description": "A knot of coral that is warm to the touch and beats four times a minute. Your weapons swing harder when you carry it.",
			"tags": ["relic", "deep"],
			"category": "relic",
			"slot_cost": 1,
			"granted_card_ids": [],
			"passive_modifiers": [
				{"kind": "card_damage_bonus", "card_tag": "weapon", "amount": 1},
			],
			"rarity": "rare",
			"universe_availability": ["lovecraft_coast"],
			"art_ref": "items/heart_of_the_reef",
		},
	]
	return out

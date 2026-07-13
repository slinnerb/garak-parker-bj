extends RefCounted
## Sample card content for the Lovecraftian Coast (Phase 2).
##
## Every real card names the item that granted it via source_item_id, and that
## item lists the card back in granted_card_ids — the link is bidirectional
## (docs/GAME_VISION.md pillar 2). The only sourceless card here is the
## effect-generated hallucination junk (tags "generated", temporary).
##
## Exercises the composable effect atoms: multi-hit (times), conditional with
## a nested add_temporary_card, and a repeat container.


static func content_type() -> String:
	return "card"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "harpoon_thrust",
			"display_name": "Harpoon Thrust",
			"description": "Deal 7 damage. The motion feels older than the arm performing it.",
			"tags": ["weapon"],
			"card_type": "attack",
			"energy_cost": 1,
			"targeting": "enemy",
			"source_item_id": "rusted_harpoon",
			"effects": [
				{"kind": "deal_damage", "params": {"amount": 7}},
			],
			"rarity": "starter",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/harpoon_thrust",
		},
		{
			"id": "brace_the_hull",
			"display_name": "Brace the Hull",
			"description": "Gain 6 block. The coat holds, the way it always has, for whoever wore it before.",
			"tags": ["defensive"],
			"card_type": "skill",
			"energy_cost": 1,
			"targeting": "self",
			"source_item_id": "oilskin_coat",
			"effects": [
				{"kind": "gain_block", "params": {"amount": 6}},
			],
			"rarity": "starter",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/brace_the_hull",
		},
		{
			"id": "lantern_sweep",
			"display_name": "Lantern Sweep",
			"description": "Deal 4 fire damage and apply 2 Burning. The flame is glad to be pointed at something.",
			"tags": ["tool", "fire"],
			"card_type": "attack",
			"energy_cost": 1,
			"targeting": "enemy",
			"source_item_id": "storm_lantern",
			"effects": [
				{"kind": "deal_damage", "params": {"amount": 4, "damage_type": "fire"}},
				{"kind": "apply_status", "params": {"status_id": "burning", "stacks": 2, "target": "enemy"}},
			],
			"rarity": "starter",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/lantern_sweep",
		},
		{
			"id": "gaff_hook",
			"display_name": "Gaff Hook",
			"description": "Deal 6 damage and apply 1 Exposed. Made for landing catch. Still is.",
			"tags": ["weapon"],
			"card_type": "attack",
			"energy_cost": 1,
			"targeting": "enemy",
			"source_item_id": "fishermans_gaff",
			"effects": [
				{"kind": "deal_damage", "params": {"amount": 6}},
				{"kind": "apply_status", "params": {"status_id": "exposed", "stacks": 1, "target": "enemy"}},
			],
			"rarity": "common",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/gaff_hook",
		},
		{
			"id": "shield_wall",
			"display_name": "Shield Wall",
			"description": "Gain 9 block and 1 Fortified. The barnacles clamp down. They are on your side, probably.",
			"tags": ["defensive"],
			"card_type": "skill",
			"energy_cost": 2,
			"targeting": "self",
			"source_item_id": "barnacle_crusted_shield",
			"effects": [
				{"kind": "gain_block", "params": {"amount": 9}},
				{"kind": "apply_status", "params": {"status_id": "fortified", "stacks": 1, "target": "self"}},
			],
			"rarity": "common",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/shield_wall",
		},
		{
			"id": "swallow_tincture",
			"display_name": "Swallow the Tincture",
			"description": "Heal 6. It tastes like the harbor at low tide. It works anyway.",
			"tags": ["consumable", "healing"],
			"card_type": "skill",
			"energy_cost": 1,
			"targeting": "self",
			"source_item_id": "tincture_of_salt",
			"effects": [
				{"kind": "heal", "params": {"amount": 6}},
			],
			"rarity": "common",
			"exhaust": true,
			"consumable": true,
			"universe_theme": "coastal_horror",
			"art_ref": "cards/swallow_tincture",
		},
		{
			"id": "flare_burst",
			"display_name": "Flare Burst",
			"description": "Deal 8 fire damage to all enemies. For one red second, everything on the beach is visible. Everything.",
			"tags": ["consumable", "fire"],
			"card_type": "attack",
			"energy_cost": 1,
			"targeting": "all_enemies",
			"source_item_id": "signal_flare",
			"effects": [
				{"kind": "deal_damage", "params": {"amount": 8, "damage_type": "fire"}},
			],
			"rarity": "common",
			"exhaust": true,
			"consumable": true,
			"universe_theme": "coastal_horror",
			"art_ref": "cards/flare_burst",
		},
		{
			"id": "weighted_net",
			"display_name": "Weighted Net",
			"description": "Apply 2 Weakened and 1 Exposed. It settles over the target like it has missed them.",
			"tags": ["tool"],
			"card_type": "skill",
			"energy_cost": 1,
			"targeting": "enemy",
			"source_item_id": "net_of_woven_hair",
			"effects": [
				{"kind": "apply_status", "params": {"status_id": "weakened", "stacks": 2, "target": "enemy"}},
				{"kind": "apply_status", "params": {"status_id": "exposed", "stacks": 1, "target": "enemy"}},
			],
			"rarity": "uncommon",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/weighted_net",
		},
		{
			"id": "murmured_ward",
			"display_name": "Murmured Ward",
			"description": "Remove Weakened and gain 4 block. The words are not in any language you speak. You know them anyway.",
			"tags": ["charm"],
			"card_type": "skill",
			"energy_cost": 1,
			"targeting": "self",
			"source_item_id": "whale_ivory_charm",
			"effects": [
				{"kind": "remove_status", "params": {"status_id": "weakened"}},
				{"kind": "gain_block", "params": {"amount": 4}},
			],
			"rarity": "uncommon",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/murmured_ward",
		},
		{
			"id": "cast_beyond",
			"display_name": "Cast Beyond",
			"description": "Deal 3 damage three times. The line goes out much further than its length.",
			"tags": ["weapon", "deep"],
			"card_type": "attack",
			"energy_cost": 2,
			"targeting": "enemy",
			"source_item_id": "abyssal_fishhook",
			"effects": [
				{
					"kind": "repeat",
					"params": {
						"times": 3,
						"effects": [
							{"kind": "deal_damage", "params": {"amount": 3}},
						],
					},
				},
			],
			"rarity": "rare",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/cast_beyond",
		},
		{
			"id": "forbidden_passage",
			"display_name": "Forbidden Passage",
			"description": "Draw 3 cards. Sometimes the tide answers back, and a whisper joins your deck.",
			"tags": ["forbidden", "knowledge"],
			"card_type": "skill",
			"energy_cost": 1,
			"targeting": "none",
			"source_item_id": "drowned_mans_journal",
			"effects": [
				{"kind": "draw_cards", "params": {"count": 3}},
				{
					"kind": "conditional",
					"params": {
						"condition": {"chance_pct": 33},
						"then": [
							{"kind": "add_temporary_card", "params": {"card_id": "half_heard_whisper", "count": 1, "destination": "draw_pile"}},
						],
					},
				},
			],
			"rarity": "rare",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/forbidden_passage",
		},
		{
			"id": "whispered_names",
			"display_name": "Whispered Names",
			"description": "Deal 14 cosmic damage and start Hallucinating. Reading the names aloud costs more than energy.",
			"tags": ["forbidden", "knowledge"],
			"card_type": "attack",
			"energy_cost": 2,
			"targeting": "enemy",
			"source_item_id": "drowned_mans_journal",
			"effects": [
				{"kind": "deal_damage", "params": {"amount": 14, "damage_type": "cosmic"}},
				{"kind": "apply_status", "params": {"status_id": "hallucinating", "stacks": 1, "target": "self"}},
			],
			"rarity": "rare",
			"exhaust": true,
			"universe_theme": "coastal_horror",
			"art_ref": "cards/whispered_names",
		},
		{
			"id": "siren_lament",
			"display_name": "Siren's Lament",
			"description": "Deal 5 cosmic damage twice. The figurehead sings both notes at once.",
			"tags": ["cursed", "deep"],
			"card_type": "attack",
			"energy_cost": 2,
			"targeting": "enemy",
			"source_item_id": "weeping_figurehead",
			"effects": [
				{"kind": "deal_damage", "params": {"amount": 5, "times": 2, "damage_type": "cosmic"}},
			],
			"rarity": "special",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/siren_lament",
		},
		{
			# The cursed item's dead weight: unplayable grief clogging the deck.
			"id": "dirge_of_the_drowned",
			"display_name": "Dirge of the Drowned",
			"description": "Unplayable. Someone is crying below the waterline, and the song takes up room in your hands.",
			"tags": ["cursed"],
			"card_type": "curse",
			"energy_cost": 1,
			"targeting": "none",
			"source_item_id": "weeping_figurehead",
			"effects": [],
			"rarity": "special",
			"universe_theme": "coastal_horror",
			"art_ref": "cards/dirge_of_the_drowned",
		},
		{
			# Effect-generated junk (see forbidden_passage and the hallucinating
			# status). No source item: it is conjured mid-combat, never kept.
			"id": "half_heard_whisper",
			"display_name": "Half-Heard Whisper",
			"description": "Unplayable. A voice you almost recognize says a word you almost understand. It is gone by morning.",
			"tags": ["generated", "mental"],
			"card_type": "status",
			"energy_cost": 1,
			"targeting": "none",
			"source_item_id": "",
			"effects": [],
			"rarity": "common",
			"exhaust": true,
			"temporary": true,
			"universe_theme": "coastal_horror",
			"art_ref": "cards/half_heard_whisper",
		},
	]
	return out

extends RefCounted
## Sample Memory Tattoo content (Phase 2).
##
## A tattoo is a permanent soul memory that re-manifests on every future body
## (master prompt section 9). The soul_identity is the mark's cross-universe
## meaning; universe_display_overrides reskin it per culture while the soul
## identity stays the same — part of the wrongness threading the mythologies
## together (docs/GAME_VISION.md pillar 4).


static func content_type() -> String:
	return "tattoo"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "broken_blade",
			"display_name": "The Broken Blade",
			"description": "A blade snapped a hand's width above the hilt. You were born with it. Everyone who sees it assumes it means something in their culture, and everyone is right.",
			"tags": ["weapon", "mark"],
			"soul_identity": "a blade snapped a hand's width above the hilt",
			"functions": [
				{"kind": "guarantee_item_family", "params": {"item_tag": "weapon"}},
				{"kind": "passive_adaptation", "params": {"adaptation": "first_weapon_attack_bonus", "amount": 2}},
			],
			"stages": [
				{"stage": 1, "requirement": {"weapon_deaths": 3}, "effect": {"adaptation": "first_weapon_attack_bonus", "amount": 4}},
				{"stage": 2, "requirement": {"weapon_deaths": 7}, "effect": {"adaptation": "first_weapon_attack_bonus", "amount": 6}},
			],
			"universe_display_overrides": {
				"lovecraft_coast": {"display_name": "The Snapped Gaff", "art_ref": "tattoos/broken_blade_coast"},
				"japanese_mythos": {"display_name": "The Shattered Tsuka", "art_ref": "tattoos/broken_blade_japan"},
				"norse_mythos": {"display_name": "The Sword That Failed", "art_ref": "tattoos/broken_blade_norse"},
			},
			"unlock_requirements": {"min_deaths": 2},
			"awareness_delta": 0.0,
		},
		{
			"id": "drowned_eye",
			"display_name": "The Drowned Eye",
			"description": "An eye that stays open underwater. Forbidden things find their way to whoever bears it, and the bearer finds their way to things best left hidden.",
			"tags": ["forbidden", "mark"],
			"soul_identity": "an eye that stays open underwater",
			"functions": [
				{"kind": "guarantee_item_family", "params": {"item_tag": "forbidden"}},
				{"kind": "unlock_events", "params": {"event_tag": "cosmic"}},
				{"kind": "modify_awareness", "params": {"delta": 1.0}},
			],
			"stages": [
				{"stage": 1, "requirement": {"drowning_deaths": 2}, "effect": {"reveal_hidden_nodes": true}},
			],
			"universe_display_overrides": {
				"lovecraft_coast": {"display_name": "The Wet Mark", "art_ref": "tattoos/drowned_eye_coast"},
				"japanese_mythos": {"display_name": "The River's Eye", "art_ref": "tattoos/drowned_eye_japan"},
			},
			"unlock_requirements": {"min_deaths": 2},
			"awareness_delta": 1.0,
		},
	]
	return out

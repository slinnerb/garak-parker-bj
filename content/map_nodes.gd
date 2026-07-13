extends RefCounted
## Sample map node archetype content (Phase 2).
##
## One archetype per NODE_TYPE. base_weight steers random placement during map
## generation; 0 means "never randomly placed" for nodes that only exist at
## fixed map positions (the boss, the story beats).


static func content_type() -> String:
	return "map_node"


static func data() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{
			"id": "node_combat",
			"display_name": "Trouble",
			"description": "Something on the road does not want you past it.",
			"node_type": "combat",
			"base_weight": 10.0,
			"icon_ref": "icons/node_combat",
		},
		{
			"id": "node_elite",
			"display_name": "Something Worse",
			"description": "The locals do not go this way anymore. They will not say why.",
			"node_type": "elite",
			"base_weight": 2.0,
			"icon_ref": "icons/node_elite",
		},
		{
			"id": "node_boss",
			"display_name": "The End of the Road",
			"description": "Whatever has been waiting stops waiting here.",
			"node_type": "boss",
			# Never rolled: the boss sits at a fixed position on every map.
			"base_weight": 0.0,
			"icon_ref": "icons/node_boss",
		},
		{
			"id": "node_item_search",
			"display_name": "Salvage",
			"description": "An abandoned place with drawers no one has opened in years.",
			"node_type": "item_search",
			"base_weight": 6.0,
			"icon_ref": "icons/node_item_search",
		},
		{
			"id": "node_event",
			"display_name": "A Strange Turn",
			"description": "Something here is slightly wrong, in a way that takes a while to name.",
			"node_type": "event",
			"base_weight": 6.0,
			"icon_ref": "icons/node_event",
		},
		{
			"id": "node_merchant",
			"display_name": "Trader",
			"description": "They have things to sell. They seem to know what you need.",
			"node_type": "merchant",
			"base_weight": 3.0,
			"icon_ref": "icons/node_merchant",
		},
		{
			"id": "node_shrine",
			"display_name": "Shrine",
			"description": "A place of worship. The symbol on it is one you keep seeing.",
			"node_type": "shrine",
			"base_weight": 2.0,
			"icon_ref": "icons/node_shrine",
		},
		{
			"id": "node_rest",
			"display_name": "Shelter",
			"description": "Somewhere dry enough to sleep. The dreams are not restful, but the body mends.",
			"node_type": "rest",
			"base_weight": 4.0,
			"icon_ref": "icons/node_rest",
		},
		{
			"id": "node_tattoo",
			"display_name": "The Mark",
			"description": "Someone here recognizes a mark you have carried since birth. You do not have a mark.",
			"node_type": "tattoo",
			"base_weight": 1.0,
			"icon_ref": "icons/node_tattoo",
		},
		{
			"id": "node_memory_anomaly",
			"display_name": "Memory Anomaly",
			"description": "You have been here before. This place was built after you died.",
			"node_type": "memory_anomaly",
			"base_weight": 1.0,
			"icon_ref": "icons/node_memory_anomaly",
		},
		{
			"id": "node_treasure",
			"display_name": "Cache",
			"description": "Left behind, or left for you.",
			"node_type": "treasure",
			"base_weight": 3.0,
			"icon_ref": "icons/node_treasure",
		},
		{
			"id": "node_story",
			"display_name": "A Quiet Moment",
			"description": "Nothing attacks. Somehow that is worse.",
			"node_type": "story",
			# Never rolled: story beats are placed by the universe script.
			"base_weight": 0.0,
			"icon_ref": "icons/node_story",
		},
	]
	return out

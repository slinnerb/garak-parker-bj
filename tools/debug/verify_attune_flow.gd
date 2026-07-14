extends SceneTree
## Verifies the Phase 4 flow: toggle items on the attunement screen -> the deck
## changes -> the chosen loadout is handed to combat and becomes the real deck.

func _initialize() -> void:
	var out_path := "user://attune_flow.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.trim_prefix("--out=")

	# --- Attunement screen: swap tincture (heal) for the abyssal fishhook ---
	var att = load("res://scenes/hub/attunement_scene.tscn").instantiate()
	root.add_child(att)
	await process_frame
	att._on_item_clicked("tincture_of_salt")   # remove -> frees a slot
	att._on_item_clicked("abyssal_fishhook")    # add -> cast_beyond joins the deck
	print("ATT slots=%d fishhook=%s tincture=%s" % [
		att._attunement.used_slots(),
		att._attunement.is_attuned("abyssal_fishhook"),
		att._attunement.is_attuned("tincture_of_salt"),
	])
	var ids: Array = []
	for item in att._attunement.attuned_items():
		ids.append(item.id)
	CombatRequest.set_request(CombatDemo.DEMO_ARCHETYPE, ids, "brine_soaked_villager")
	att.queue_free()
	await process_frame

	# --- Combat scene: must build its deck from that loadout ---
	var combat = load("res://scenes/combat/combat_scene.tscn").instantiate()
	root.add_child(combat)
	await process_frame
	var deck_ids: Array = []
	var p = combat._combat.player
	for pile in [p.hand, p.draw_pile, p.discard_pile]:
		for c in pile:
			deck_ids.append(c.id())
	print("COMBAT deck size=%d has_cast_beyond=%s has_swallow=%s" % [
		deck_ids.size(), deck_ids.has("cast_beyond"), deck_ids.has("swallow_tincture"),
	])

	for _i in 12:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out_path)
	print("Saved -> %s" % ProjectSettings.globalize_path(out_path))
	quit(0)

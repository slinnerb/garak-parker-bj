extends TestCase
## Phase 6 domain tests: the death report, Remembrance, adaptation eligibility,
## soul progression (pure — profile passed as a dict, the real save is never
## touched), and adaptations making the next life measurably stronger in combat.

func test_death_report_captures_the_death() -> void:
	var run := _run_two_steps(11)
	var killer: EnemyDefinition = ContentRegistry.get_def("enemy", "brine_soaked_villager")
	var report := DeathReport.build(run, killer, 1)
	assert_eq(report.universe_id, "lovecraft_coast", "records the universe")
	assert_eq(report.killer_id, "brine_soaked_villager", "records the killer")
	assert_true(report.death_cause_tags.has("drowned"), "killer tags become cause tags")
	assert_true(report.death_cause_tags.has("drowning"), "a drowned killer implies a drowning death")
	assert_eq(report.rows_survived, 1, "distance is the row the body fell on")
	assert_true(report.carried_item_ids.has("rusted_harpoon"), "carried items are recorded")
	assert_gt(report.remembrance, 0, "every death grants remembrance")
	_reset()

func test_remembrance_scales_with_distance_and_feats() -> void:
	var shallow := DeathReport.new()
	shallow.rows_survived = 1
	var deep := DeathReport.new()
	deep.rows_survived = 5
	deep.elites_defeated = 1
	deep.boss_reached = true
	assert_gt(DeathReport.calculate_remembrance(deep), DeathReport.calculate_remembrance(shallow),
		"a longer, bolder life teaches the soul more")

func test_adaptation_eligibility_matches_triggers() -> void:
	_load_content()
	var report := DeathReport.new()
	report.universe_id = "lovecraft_coast"
	report.death_cause_tags.assign(["human", "drowned", "drowning"])
	var eligible := SoulProgression.eligible_adaptations(ContentRegistry, report, [])
	var ids := _ids(eligible)
	assert_true(ids.has("gills_that_should_not_be"), "a drowning death offers the gills")
	assert_false(ids.has("scar_of_the_first_light"), "no boss involved -> no boss scar")
	# Dying to the boss (tagged boss+cosmic) in lovecraft offers the scar.
	var boss_report := DeathReport.new()
	boss_report.universe_id = "lovecraft_coast"
	boss_report.death_cause_tags.assign(["boss", "cosmic"])
	var boss_ids := _ids(SoulProgression.eligible_adaptations(ContentRegistry, boss_report, []))
	assert_true(boss_ids.has("scar_of_the_first_light"), "a boss death in lovecraft offers the scar")
	assert_true(boss_ids.has("eyes_adjusted_to_the_dark"), "a cosmic death offers the eyes")
	ContentRegistry.clear()

func test_owned_adaptations_are_not_reoffered() -> void:
	_load_content()
	var report := DeathReport.new()
	report.universe_id = "lovecraft_coast"
	report.death_cause_tags.assign(["drowning"])
	var ids := _ids(SoulProgression.eligible_adaptations(ContentRegistry, report, ["gills_that_should_not_be"]))
	assert_false(ids.has("gills_that_should_not_be"), "the soul can't learn the same lesson twice")
	ContentRegistry.clear()

func test_apply_death_updates_profile_and_unlocks_tattoos() -> void:
	var profile := SaveManager.default_data("profile")
	var report := DeathReport.new()
	report.universe_id = "lovecraft_coast"
	report.remembrance = 35
	var first := SoulProgression.apply_death(profile, report, "gills_that_should_not_be")
	assert_eq(int(profile["death_count"]), 1, "death count increments")
	assert_eq(int(profile["remembrance"]), 35, "remembrance accrues")
	assert_true((profile["adaptations"] as Array).has("gills_that_should_not_be"), "the chosen adaptation persists")
	assert_false(bool(first["tattoo_just_unlocked"]), "tattoos stay locked after one death")
	var second := SoulProgression.apply_death(profile, report, "")
	assert_true(bool(second["tattoo_just_unlocked"]), "the second death unlocks the tattoo system")
	assert_true(bool(profile["tattoo_system_unlocked"]), "and the profile records it")
	assert_eq(int(profile["tattoo_slots"]), 1, "with one tattoo slot to start")

func test_begin_life_tracks_history_and_unlocks() -> void:
	var profile := SaveManager.default_data("profile")
	SoulProgression.begin_life(profile, "lovecraft_coast")
	SoulProgression.begin_life(profile, "japanese_mythos")
	assert_eq(int(profile["life_count"]), 2, "life count increments per life")
	assert_eq(profile["universe_history"], ["lovecraft_coast", "japanese_mythos"], "history keeps order")
	assert_true((profile["unlocked_universes"] as Array).has("japanese_mythos"), "living a universe unlocks it")

func test_adaptations_make_combat_measurably_stronger() -> void:
	_load_content()
	# The boss-scar: +10% damage vs anything tagged "boss".
	var mods := SoulProgression.combat_modifiers(ContentRegistry, ["scar_of_the_first_light"])
	assert_eq(float(mods["bonus_vs_tags"]["boss"]), 1.1, "the scar maps to a +10% bonus vs boss tags")
	# Same seed, same fight vs the boss — with and without the scar.
	var without := _boss_damage_after_one_harpoon([])
	var with_scar := _boss_damage_after_one_harpoon(["scar_of_the_first_light"])
	assert_gt(with_scar, without, "the scarred soul hits the boss harder (%d > %d)" % [with_scar, without])
	# And the gills: less damage taken from the drowned.
	var taken_mods := SoulProgression.combat_modifiers(ContentRegistry, ["gills_that_should_not_be"])
	assert_eq(float(taken_mods["taken_vs_tags"]["drowned"]), 0.75, "gills map to 25% less taken from the drowned")
	ContentRegistry.clear()

# ---------------------------------------------------------------------------

func _load_content() -> void:
	ContentRegistry.clear()
	ContentLoader.load_all(ContentRegistry)

## Starts a run and walks two steps in (so distance/carried items are real).
func _run_two_steps(seed_value: int) -> RunState:
	_load_content()
	var run := RunManager.start_run(ContentRegistry, seed_value, "lovecraft_coast", "coastal_drifter")
	run.travel_to(run.available_next()[0].id)
	run.travel_to(run.available_next()[0].id)
	return run

func _reset() -> void:
	RunManager.end_run()
	ContentRegistry.clear()

func _ids(defs: Array) -> Array:
	var out: Array = []
	for def in defs:
		out.append(def.id)
	return out

## Damage dealt to the boss by one harpoon_thrust under the given adaptations
## (same seed both times, so only the adaptations differ).
func _boss_damage_after_one_harpoon(adaptation_ids: Array) -> int:
	var rng := RngStream.new(77)
	var player := PlayerState.new("player", "W", 70, 3, 5)
	player.add_to_draw_pile(CardInstance.new(ContentRegistry.get_def("card", "harpoon_thrust")))
	var boss := EnemyState.from_definition(ContentRegistry.get_def("enemy", "lighthouse_keeper"), rng)
	var combat := CombatState.new(ContentRegistry, rng, player, [boss])
	combat.player_modifiers = SoulProgression.combat_modifiers(ContentRegistry, adaptation_ids)
	combat.start_combat()
	var before := boss.hp
	combat.play_card(0, 0)
	return before - boss.hp

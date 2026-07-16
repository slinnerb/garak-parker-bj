extends Node
## Meta-progression service (autoload singleton: `Soul`) — Phase 6.
##
## The soul is what survives death. This wraps the pure SoulProgression rules
## with profile persistence: every mutation goes through SaveManager's atomic
## write, so a crash never loses a death's reward (§7 step 14: save
## meta-progression atomically). Reads are cheap passthroughs.

func profile() -> Dictionary:
	return SaveManager.get_profile()


func life_count() -> int:
	return int(profile().get("life_count", 0))


func death_count() -> int:
	return int(profile().get("death_count", 0))


func remembrance() -> int:
	return int(profile().get("remembrance", 0))


func adaptations() -> Array:
	return profile().get("adaptations", [])


func tattoo_system_unlocked() -> bool:
	return bool(profile().get("tattoo_system_unlocked", false))


## Records a death permanently: remembrance, the chosen adaptation, death
## counters, and the tattoo-system unlock. Returns SoulProgression.apply_death's
## outcome flags (remembrance_gained, tattoo_just_unlocked).
func record_death(report: DeathReport, chosen_adaptation_id: String = "") -> Dictionary:
	var data := profile()
	var outcome := SoulProgression.apply_death(data, report, chosen_adaptation_id)
	SaveManager.set_data("profile", data)
	Log.info(Log.Cat.DEATH, "Death recorded: %s (+%d remembrance%s)" % [
		report.summary(), int(outcome.get("remembrance_gained", 0)),
		", tattoos UNLOCKED" if bool(outcome.get("tattoo_just_unlocked", false)) else "",
	])
	return outcome


## Marks a new life begun (life count, universe history + unlock) and persists.
func begin_life(universe_id: String) -> void:
	var data := profile()
	SoulProgression.begin_life(data, universe_id)
	SaveManager.set_data("profile", data)
	Log.info(Log.Cat.RUN, "Life %d begins in %s" % [int(data.get("life_count", 0)), universe_id])


## The universe the next life reincarnates into (fixed order, then weighted).
func select_next_universe(content, rng: RngStream) -> String:
	return UniverseSelector.select_next(content, profile(), rng)

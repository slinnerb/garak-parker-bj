class_name DeathReport
extends RefCounted
## The record of one death (Phase 6, master prompt §7).
##
## Death is the most important system in the game: when a life ends, this
## captures what killed the body, where, and what it was carrying — the facts
## that drive Remembrance, adaptation eligibility, universe weighting, and the
## Moment of Recall's narration. Pure data, built once at the moment of death.

var universe_id: String = ""
var life_number: int = 1
## The enemy that landed the killing blow ("" when death had no single killer).
var killer_id: String = ""
var killer_name: String = ""
## Tags describing how death happened. Includes the killer's tags plus derived
## causes (e.g. dying to a drowned/deep thing is a drowning). Adaptation
## triggers match against these.
var death_cause_tags: Array[String] = []
## How far the body made it: map rows survived, and the total, for "distance".
var rows_survived: int = 0
var total_rows: int = 0
var elites_defeated: int = 0
var boss_reached: bool = false
## Ids and tags of every item carried at death (both are useful: ids for lore,
## tags for adaptation triggers like carried_item_tags).
var carried_item_ids: Array[String] = []
var carried_item_tags: Array[String] = []
## The permanent reward this death grants the soul.
var remembrance: int = 0

## Tags that imply a derived cause when they appear on the killer.
const DERIVED_CAUSES := {
	"drowned": "drowning",
	"deep": "drowning",
	"cosmic": "cosmic",
	"fire": "burning",
}


## Builds the report from the run that just ended and the enemy that ended it.
## `killer` may be null (future non-combat deaths). Pure — no autoloads.
static func build(run: RunState, killer: EnemyDefinition, life_number_: int) -> DeathReport:
	var report := DeathReport.new()
	report.universe_id = run.universe_id
	report.life_number = life_number_

	if killer != null:
		report.killer_id = killer.id
		report.killer_name = killer.display_name
		for tag in killer.tags:
			if not report.death_cause_tags.has(tag):
				report.death_cause_tags.append(tag)
			var derived: String = DERIVED_CAUSES.get(tag, "")
			if not derived.is_empty() and not report.death_cause_tags.has(derived):
				report.death_cause_tags.append(derived)

	var node := run.current_node()
	report.rows_survived = node.row if node != null else 0
	report.total_rows = run.map.rows if run.map != null else 0
	report.boss_reached = run.at_boss()
	# Every visited elite node before the death site was a won fight (you can't
	# move past a fight you lost).
	for node_id in run.visited:
		if node_id == run.current_node_id:
			continue
		var visited_node: MapNode = run.map.get_node(node_id) if run.map != null else null
		if visited_node != null and visited_node.node_type == "elite":
			report.elites_defeated += 1

	if run.inventory != null:
		for item in run.inventory.all():
			report.carried_item_ids.append(item.id)
			for tag in item.tags:
				if not report.carried_item_tags.has(tag):
					report.carried_item_tags.append(tag)

	report.remembrance = calculate_remembrance(report)
	return report


## The permanent reward for a death. Deliberately simple and legible: distance
## is the main driver, elites are worth real credit, reaching the boss more so,
## and carrying forbidden things at death feeds the soul (they remember you).
static func calculate_remembrance(report: DeathReport) -> int:
	var total := 10                                # every death teaches something
	total += report.rows_survived * 5
	total += report.elites_defeated * 15
	if report.boss_reached:
		total += 40
	if report.carried_item_tags.has("forbidden"):
		total += 10
	if report.carried_item_tags.has("cursed"):
		total += 10
	return total


## One-line summary for logs and the Moment of Recall header.
func summary() -> String:
	var who := killer_name if not killer_name.is_empty() else "the coast itself"
	return "Life %d ended in %s — slain by %s, %d rows in." % [life_number, universe_id, who, rows_survived]

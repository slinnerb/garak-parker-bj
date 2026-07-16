class_name ActionHand
extends RefCounted
## Loot → hand (Action Arc): builds the freeze-card hand from the run's
## Attunement, so the items you find and attune ARE how you fight.
##
## Each attuned item's granted cards become ActionCards: the turn-based
## CardDefinition's primary effect picks the real-time kind, its numbers scale up
## to action pacing, and its energy cost sets the cooldown. Pure & testable —
## the action room calls this when a run fight starts; the dev sandbox keeps the
## default hand. Riders we can't express yet (statuses, draws) become bonus power
## rather than silently vanishing.

const MAX_HAND := 6          # keys 1-6; a loadout picker can come later
const DAMAGE_SCALE := 2.5    # turn-based numbers are small; action pacing isn't
const BLOCK_SCALE := 3.0
const HEAL_SCALE := 2.5
const RIDER_BONUS := 3.0     # per extra effect not yet modelled in real time

const KIND_COLORS := {
	"bolt": Color(0.55, 0.85, 1.0),
	"lash": Color(0.78, 0.96, 1.0),
	"ward": Color(0.52, 0.80, 0.72),
	"heal": Color(0.55, 0.82, 0.55),
	"riptide": Color(0.92, 0.72, 0.42),
}
const KIND_DESC := {
	"bolt": "Fire a bolt at the enemy",
	"lash": "Slash a foe right beside you",
	"ward": "Cloak yourself in a shield",
	"heal": "Mend your spectral form",
	"riptide": "Lunge to the enemy and strike",
}


## The hand for a run: unique cards from attuned items, in attunement order,
## capped at MAX_HAND. Returns [] when nothing is attuned / no cards granted —
## the caller should fall back to the default hand rather than fight bare.
static func build_hand(content, attunement) -> Array:
	var out: Array = []
	if attunement == null:
		return out
	var seen := {}
	for item in attunement.attuned_items():
		for cid in item.granted_card_ids:
			if seen.has(cid) or out.size() >= MAX_HAND:
				continue
			var card_def = content.get_def("card", cid)
			if card_def == null:
				continue
			seen[cid] = true
			out.append(map_card(card_def))
	return out


## Translates one turn-based CardDefinition into a real-time ActionCard.
## Primary effect → kind; "weapon"-tagged damage is a melee lash, other damage a
## ranged bolt; block → ward; heal → heal. Anything else becomes a modest bolt
## (a raw discharge of spirit) so no item ever grants a dead card.
static func map_card(def) -> ActionCard:
	var kind: String = ActionCard.BOLT
	var power := 5.0 + 3.0 * float(def.energy_cost)
	var primary = def.effects[0] if not def.effects.is_empty() else null
	if primary != null:
		match primary.kind:
			"deal_damage":
				kind = ActionCard.LASH if def.tags.has("weapon") else ActionCard.BOLT
				power = float(primary.params.get("amount", 4)) * DAMAGE_SCALE
			"gain_block":
				kind = ActionCard.WARD
				power = float(primary.params.get("amount", 4)) * BLOCK_SCALE
			"heal":
				kind = ActionCard.HEAL
				power = float(primary.params.get("amount", 4)) * HEAL_SCALE
	if def.effects.size() > 1:
		power += RIDER_BONUS * float(def.effects.size() - 1)
	var cooldown := 1.0 + 1.2 * float(maxi(1, def.energy_cost))
	return ActionCard.new(def.id, def.display_name, kind, roundf(power), cooldown,
		KIND_COLORS.get(kind, Color.WHITE), KIND_DESC.get(kind, "A surge of spirit"))

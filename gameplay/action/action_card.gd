class_name ActionCard
extends RefCounted
## A queued real-time ability (Action Arc, Phase B). The player's attuned loadout
## becomes a hand of these: you queue them during the freeze and they execute in
## a burst on release, then go on cooldown. Data-only — the room resolves the
## effect. Sourced from a fixed default hand for now; a later slice builds these
## from the run's Attunement (items -> deck -> hand), keeping the same data shape.

const BOLT := "bolt"        # ranged spirit projectile
const LASH := "lash"        # instant melee damage in reach
const WARD := "ward"        # self shield that absorbs incoming damage
const RIPTIDE := "riptide"  # lunge to the enemy + damage on arrival

var id: String
var display_name: String
var kind: String
var power: float
var cooldown: float
var color: Color
var description: String


func _init(p_id: String = "", p_name: String = "", p_kind: String = BOLT,
		p_power: float = 10.0, p_cooldown: float = 2.0, p_color: Color = Color.WHITE,
		p_desc: String = "") -> void:
	id = p_id
	display_name = p_name
	kind = p_kind
	power = p_power
	cooldown = p_cooldown
	color = p_color
	description = p_desc


## The stand-in loadout until the Attunement screen feeds real cards in.
static func default_hand() -> Array:
	return [
		ActionCard.new("wailing_bolt", "Wailing Bolt", BOLT, 18.0, 1.6, Color(0.55, 0.85, 1.0), "Fire a bolt at the enemy"),
		ActionCard.new("spirit_lash", "Spirit Lash", LASH, 26.0, 2.6, Color(0.78, 0.96, 1.0), "Slash a foe right beside you"),
		ActionCard.new("drowned_ward", "Drowned Ward", WARD, 34.0, 4.5, Color(0.52, 0.80, 0.72), "Cloak yourself in a shield"),
		ActionCard.new("rip_tide", "Rip Tide", RIPTIDE, 24.0, 3.4, Color(0.92, 0.72, 0.42), "Lunge to the enemy and strike"),
	]

extends Node2D
## The Drowned One — a telegraphed melee stalker (Action Arc, Phase A). It chases,
## winds up a readable strike, hits, then recovers. Its movement and wind-up scale
## with the room's `time_factor`, so entering focus visibly slows it and opens the
## dodge window — the payoff of the freeze-to-plan loop.

signal died
signal hp_changed(hp: float, max_hp: float)

enum St { CHASE, WINDUP, STRIKE, RECOVER }

const SPEED := 98.0
const ATTACK_RANGE := 46.0
const STRIKE_REACH := 62.0
const WINDUP_TIME := 0.72
const STRIKE_TIME := 0.16
const RECOVER_TIME := 0.66

const BODY := Color(0.62, 0.16, 0.22)
const TELL := Color(0.98, 0.62, 0.34)
const EYE := Color(0.95, 0.95, 0.90)

var max_hp := 64.0
var hp := 64.0
var hit_radius := 22.0
var strike_damage := 14.0
var room = null       # the ActionRoom (for time_factor + bounds)
var target = null     # the player


## Shape this enemy from a run's EnemyDefinition (HP + tier-scaled threat).
func configure(def) -> void:
	max_hp = float(maxi(1, def.base_hp))
	hp = max_hp
	if def.is_boss:
		strike_damage = 24.0
		hit_radius = 30.0
	elif def.is_elite:
		strike_damage = 18.0
		hit_radius = 26.0
	else:
		strike_damage = 13.0
		hit_radius = 22.0

var _state := St.CHASE
var _t := 0.0
var _flash := 0.0


func _ready() -> void:
	add_to_group("action_enemy")


func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	_flash = 0.10
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		died.emit()
		queue_free()


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)  # visual, real-time
	if target == null or not is_instance_valid(target):
		queue_redraw()
		return
	var tf: float = room.time_factor if room != null else 1.0
	var d := delta * tf  # world time — slowed while the player is focusing

	match _state:
		St.CHASE:
			var to: Vector2 = target.position - position
			if to.length() <= ATTACK_RANGE:
				_state = St.WINDUP
				_t = WINDUP_TIME
			elif to.length() > 0.01:
				position += to.normalized() * SPEED * d
		St.WINDUP:
			_t -= d
			if _t <= 0.0:
				_state = St.STRIKE
				_t = STRIKE_TIME
				_resolve_strike()
		St.STRIKE:
			_t -= d
			if _t <= 0.0:
				_state = St.RECOVER
				_t = RECOVER_TIME
		St.RECOVER:
			_t -= d
			if _t <= 0.0:
				_state = St.CHASE

	if room != null:
		position = room.clamp_to_arena(position)
	queue_redraw()


## The strike lands at the end of the wind-up. Dodge (i-frames) or step out of
## reach in time and it whiffs.
func _resolve_strike() -> void:
	if target == null or not is_instance_valid(target):
		return
	if position.distance_to(target.position) <= STRIKE_REACH and not target.is_invulnerable():
		target.take_damage(strike_damage)


func _draw() -> void:
	var r := hit_radius
	var col := BODY
	if _state == St.WINDUP:
		var p := 1.0 - clampf(_t / WINDUP_TIME, 0.0, 1.0)  # 0 -> 1 across the wind-up
		r += 9.0 * p
		col = BODY.lerp(TELL, p)
	elif _state == St.STRIKE:
		col = TELL
	if _flash > 0.0:
		col = col.lerp(Color.WHITE, 0.6)

	# A jagged, drowned silhouette.
	var pts := PackedVector2Array([
		Vector2(0, -r), Vector2(r * 0.72, -r * 0.1),
		Vector2(r * 0.32, r), Vector2(-r * 0.32, r), Vector2(-r * 0.72, -r * 0.1),
	])
	draw_colored_polygon(pts, col)
	draw_circle(Vector2(0, -r * 0.25), r * 0.16, EYE)

	# Telegraph the reach as it strikes.
	if _state == St.STRIKE:
		draw_arc(Vector2.ZERO, STRIKE_REACH, 0.0, TAU, 30, Color(0.98, 0.62, 0.34, 0.5), 3.0)

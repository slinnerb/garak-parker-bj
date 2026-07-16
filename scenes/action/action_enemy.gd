extends Node2D
## A foe of the drowned coast (Action Arc). One state machine, three behaviors:
##   melee  — chase and land a telegraphed strike (the default)
##   swarm  — fast and fragile; quick, weak lunges that punish standing still
##   ranged — holds its distance and fires dodgeable wails that slow under focus
## Movement and wind-ups scale with the room's `time_factor`, so focusing
## visibly slows the threat — the payoff of the freeze-to-plan loop.

signal died
signal hp_changed(hp: float, max_hp: float)
signal damaged(amount: float, at: Vector2)

enum St { CHASE, WINDUP, STRIKE, RECOVER }

const EnemyBolt := preload("res://scenes/action/enemy_bolt.gd")

const KNOCKBACK_FORCE := 260.0
const KNOCKBACK_DECAY := 1100.0
const HITSTOP := 0.05

# Ranged band: retreat inside min, advance beyond max, fire within fire range.
const RANGED_MIN := 200.0
const RANGED_MAX := 430.0
const RANGED_FIRE := 500.0
const SHOT_SPEED := 300.0

const BODY := Color(0.62, 0.16, 0.22)
const BODY_RANGED := Color(0.47, 0.22, 0.45)
const TELL := Color(0.98, 0.62, 0.34)
const EYE := Color(0.95, 0.95, 0.90)

var max_hp := 64.0
var hp := 64.0
var hit_radius := 22.0
var strike_damage := 14.0
var behavior := "melee"

# Tunables (melee defaults; configure() re-tunes per behavior and tier).
var speed := 98.0
var attack_range := 46.0
var strike_reach := 62.0
var windup_time := 0.72
var strike_time := 0.16
var recover_time := 0.66

var room = null       # the ActionRoom (time_factor + bounds + projectiles)
var target = null     # the player

var _state := St.CHASE
var _t := 0.0
var _flash := 0.0
var _knockback := Vector2.ZERO
var _hitstop := 0.0


func _ready() -> void:
	add_to_group("action_enemy")


## Shape this enemy from a run's EnemyDefinition: HP, its action behavior
## preset, then tier scaling for elites and bosses.
func configure(def) -> void:
	max_hp = float(maxi(1, def.base_hp))
	hp = max_hp
	behavior = str(def.action_behavior)
	match behavior:
		"swarm":
			speed = 178.0
			windup_time = 0.34
			strike_time = 0.12
			recover_time = 0.42
			attack_range = 40.0
			strike_reach = 52.0
			strike_damage = 8.0
			hit_radius = 15.0
		"ranged":
			speed = 82.0
			windup_time = 0.85
			strike_time = 0.14
			recover_time = 1.05
			strike_damage = 10.0
			hit_radius = 20.0
		_:
			strike_damage = 13.0
	if def.is_boss:
		strike_damage *= 1.8
		hit_radius += 8.0
	elif def.is_elite:
		strike_damage *= 1.4
		hit_radius += 4.0


func take_damage(amount: float, from_pos: Vector2 = Vector2.INF) -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	_flash = 0.12
	_hitstop = HITSTOP
	if from_pos.is_finite():
		_knockback = (position - from_pos).normalized() * KNOCKBACK_FORCE
	damaged.emit(amount, position)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		died.emit()
		queue_free()


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)  # visual, real-time
	# Knockback decays in real time so hits stay snappy regardless of focus.
	if _knockback.length() > 1.0:
		position += _knockback * delta
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	if _hitstop > 0.0:
		_hitstop -= delta
		if room != null:
			position = room.clamp_to_arena(position)
		queue_redraw()
		return  # a brief hitch on impact — the AI pauses while the hit lands
	if target == null or not is_instance_valid(target):
		queue_redraw()
		return
	var tf: float = room.time_factor if room != null else 1.0
	var d := delta * tf  # world time — slowed while the player is focusing

	match _state:
		St.CHASE:
			var to: Vector2 = target.position - position
			var dist := to.length()
			if behavior == "ranged":
				if dist < RANGED_MIN and dist > 0.01:
					position -= to.normalized() * speed * d
				elif dist > RANGED_MAX:
					position += to.normalized() * speed * d
				if dist <= RANGED_FIRE:
					_state = St.WINDUP
					_t = windup_time
			else:
				if dist <= attack_range:
					_state = St.WINDUP
					_t = windup_time
				elif dist > 0.01:
					position += to.normalized() * speed * d
		St.WINDUP:
			_t -= d
			if _t <= 0.0:
				_state = St.STRIKE
				_t = strike_time
				if behavior == "ranged":
					_fire_shot()
				else:
					_resolve_strike()
		St.STRIKE:
			_t -= d
			if _t <= 0.0:
				_state = St.RECOVER
				_t = recover_time
		St.RECOVER:
			_t -= d
			# Ranged foes drift back to their preferred distance while recovering.
			if behavior == "ranged":
				var away: Vector2 = target.position - position
				if away.length() < RANGED_MIN and away.length() > 0.01:
					position -= away.normalized() * speed * d
			if _t <= 0.0:
				_state = St.CHASE

	if room != null:
		position = room.clamp_to_arena(position)
	queue_redraw()


## Melee/swarm: the strike lands at the end of the wind-up. Dodge (i-frames) or
## step out of reach in time and it whiffs.
func _resolve_strike() -> void:
	if target == null or not is_instance_valid(target):
		return
	if position.distance_to(target.position) <= strike_reach and not target.is_invulnerable():
		target.take_damage(strike_damage, position)


## Ranged: loose a wail at where the specter is right now — lead it, dodge it,
## or slow the world and walk between the shots.
func _fire_shot() -> void:
	if target == null or not is_instance_valid(target) or room == null:
		return
	var bolt := EnemyBolt.new()
	bolt.position = position
	bolt.room = room
	bolt.target = target
	bolt.setup(target.position - position, strike_damage, SHOT_SPEED)
	room.spawn_projectile(bolt)


func _draw() -> void:
	var r := hit_radius
	var col := BODY_RANGED if behavior == "ranged" else BODY
	if _state == St.WINDUP:
		var p := 1.0 - clampf(_t / windup_time, 0.0, 1.0)
		r += 9.0 * p
		col = col.lerp(TELL, p)
	elif _state == St.STRIKE:
		col = TELL
	if _flash > 0.0:
		col = col.lerp(Color.WHITE, 0.6)

	var pts: PackedVector2Array
	if behavior == "ranged":
		# A hooded, wailing silhouette with an open mouth.
		pts = PackedVector2Array([
			Vector2(0, -r * 1.25), Vector2(r * 0.62, -r * 0.25),
			Vector2(r * 0.45, r), Vector2(-r * 0.45, r), Vector2(-r * 0.62, -r * 0.25),
		])
	else:
		pts = PackedVector2Array([
			Vector2(0, -r), Vector2(r * 0.72, -r * 0.1),
			Vector2(r * 0.32, r), Vector2(-r * 0.32, r), Vector2(-r * 0.72, -r * 0.1),
		])
	draw_colored_polygon(pts, col)
	if behavior == "ranged":
		draw_circle(Vector2(0, r * 0.05), r * 0.30, Color(0.07, 0.03, 0.08))
	else:
		draw_circle(Vector2(0, -r * 0.25), r * 0.16, EYE)

	if _state == St.STRIKE:
		if behavior == "ranged":
			draw_circle(Vector2(0, r * 0.05), r * 0.44, Color(0.98, 0.62, 0.34, 0.5))
		else:
			draw_arc(Vector2.ZERO, strike_reach, 0.0, TAU, 30, Color(0.98, 0.62, 0.34, 0.5), 3.0)

extends Node2D
## The specter — the Phase-One player (Action Arc, Phase A). Free 8-directional
## movement, a dodge with invulnerability frames, and a spirit-bolt attack aimed
## at the cursor. Always runs at real time, so during focus the *world* slows
## around you (bullet-time) while you stay responsive.

signal died
signal hp_changed(hp: float, max_hp: float)
signal damaged(amount: float, at: Vector2)

const SpiritBolt := preload("res://scenes/action/spirit_bolt.gd")

const KNOCKBACK_FORCE := 210.0
const KNOCKBACK_DECAY := 1200.0

const SPEED := 250.0
const DODGE_SPEED := 680.0
const DODGE_TIME := 0.16
const DODGE_COOLDOWN := 0.5
const IFRAME_TIME := 0.26
const HIT_MERCY_IFRAME := 0.14
const ATTACK_COOLDOWN := 0.26
const BOLT_DAMAGE := 12.0
const RADIUS := 13.0

const MAX_SHIELD := 60.0

const CORE := Color(0.80, 0.96, 1.0)
const AURA := Color(0.45, 0.80, 0.95, 0.28)
const TAIL := Color(0.60, 0.90, 1.0, 0.40)
const SHIELD_COL := Color(0.55, 0.85, 0.80, 0.85)

var max_hp := 100.0
var hp := 100.0
var shield := 0.0
var room = null

var _dodge_t := 0.0
var _dodge_cd := 0.0
var _iframe := 0.0
var _atk_cd := 0.0
var _dodge_dir := Vector2.RIGHT
var _facing := Vector2.RIGHT
var _knockback := Vector2.ZERO
var _dead := false


func is_invulnerable() -> bool:
	return _iframe > 0.0


func is_dead() -> bool:
	return _dead


func take_damage(amount: float, from_pos: Vector2 = Vector2.INF) -> void:
	if _dead or is_invulnerable():
		return
	if shield > 0.0:
		var absorbed := minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
	if amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	_iframe = HIT_MERCY_IFRAME  # brief flicker so a single mistake isn't a chain-death
	if from_pos.is_finite():
		_knockback = (position - from_pos).normalized() * KNOCKBACK_FORCE
	damaged.emit(amount, position)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_dead = true
		died.emit()


## Ward card — a shell that soaks incoming damage before HP.
func add_shield(amount: float) -> void:
	shield = minf(MAX_SHIELD, shield + amount)


## Heal card — mends the spectral form.
func heal(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)


## Rip Tide card — an i-frame lunge that arrives AT the target: the dash length
## is clamped to the actual distance (stopping a hair short) so it neither
## whiffs at range nor overshoots point-blank. Capped at 1.5x a dodge.
func dash_toward(point: Vector2) -> void:
	if _dead:
		return
	var dir := point - position
	var dist := dir.length()
	_dodge_dir = dir.normalized() if dist > 1.0 else _facing
	_facing = _dodge_dir
	var lunge := clampf(dist - 26.0, 40.0, DODGE_SPEED * DODGE_TIME * 1.5)
	_dodge_t = lunge / DODGE_SPEED
	_iframe = maxf(_iframe, IFRAME_TIME)
	_dodge_cd = DODGE_COOLDOWN


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_dodge_cd = maxf(0.0, _dodge_cd - delta)
	_iframe = maxf(0.0, _iframe - delta)
	_atk_cd = maxf(0.0, _atk_cd - delta)

	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move.length() > 0.15:
		_facing = move.normalized()

	if _dodge_t > 0.0:
		_dodge_t -= delta
		position += _dodge_dir * DODGE_SPEED * delta
	else:
		if move.length() > 0.15:
			position += move.normalized() * SPEED * delta
		if Input.is_action_just_pressed("dodge") and _dodge_cd <= 0.0:
			_dodge_dir = _facing
			_dodge_t = DODGE_TIME
			_iframe = IFRAME_TIME
			_dodge_cd = DODGE_COOLDOWN

	if Input.is_action_pressed("spirit_attack") and _atk_cd <= 0.0:
		_fire_bolt()
		_atk_cd = ATTACK_COOLDOWN

	if _knockback.length() > 1.0:
		position += _knockback * delta
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	if room != null:
		position = room.clamp_to_arena(position)
	queue_redraw()


func _fire_bolt() -> void:
	var dir := get_global_mouse_position() - global_position
	if dir.length() < 4.0:
		dir = _facing
	var bolt := SpiritBolt.new()
	bolt.position = position
	bolt.setup(dir.normalized(), BOLT_DAMAGE)
	if room != null:
		room.spawn_projectile(bolt)
	elif get_parent() != null:
		get_parent().add_child(bolt)


func _draw() -> void:
	var aura := AURA
	var core := CORE
	if _iframe > 0.0 and int(_iframe * 40.0) % 2 == 0:
		core = core.lerp(Color(1, 1, 1, 0.6), 0.5)
		aura.a *= 0.4
	draw_circle(Vector2.ZERO, RADIUS * 2.0, aura)
	draw_circle(Vector2.ZERO, RADIUS, core)
	draw_line(Vector2.ZERO, -_facing * RADIUS * 1.8, TAIL, 5.0)  # a wispy tail
	if shield > 0.0:
		var col := SHIELD_COL
		col.a *= clampf(shield / MAX_SHIELD, 0.3, 1.0)
		draw_arc(Vector2.ZERO, RADIUS * 2.4, 0.0, TAU, 32, col, 3.0)

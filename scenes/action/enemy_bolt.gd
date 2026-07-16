extends Node2D
## A wailing shot from a ranged foe (Action Arc — enemy variety). Travels in
## WORLD time: it slows under focus, so freezing time is how you read and thread
## a volley. Passes harmlessly through a dodging (invulnerable) specter.

const RADIUS := 7.0
const PLAYER_RADIUS := 13.0
const CORE := Color(0.86, 0.42, 0.62)
const GLOW := Color(0.72, 0.22, 0.44, 0.35)

var room = null      # for time_factor
var target = null    # the player
var _vel := Vector2.ZERO
var _damage := 10.0
var _life := 3.5


func _ready() -> void:
	add_to_group("action_projectile")  # swept by the room when the fight ends


func setup(dir: Vector2, damage: float, speed: float) -> void:
	_vel = dir.normalized() * speed
	_damage = damage


func _physics_process(delta: float) -> void:
	var tf: float = room.time_factor if room != null else 1.0
	var d := delta * tf
	position += _vel * d
	_life -= d
	if _life <= 0.0:
		queue_free()
		return
	if target != null and is_instance_valid(target) and not target.is_dead():
		if position.distance_to(target.position) <= RADIUS + PLAYER_RADIUS and not target.is_invulnerable():
			target.take_damage(_damage, position)
			queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS * 2.2, GLOW)
	draw_circle(Vector2.ZERO, RADIUS, CORE)

extends Node2D
## The specter's spirit bolt — the basic ranged attack (Action Arc, Phase A).
## Travels at full speed even during focus (your own actions stay crisp while the
## world slows around you), and damages the first enemy it touches.

const SPEED := 640.0
const RADIUS := 6.0
const LIFETIME := 1.5
const CORE := Color(0.80, 0.96, 1.0)
const GLOW := Color(0.35, 0.75, 0.95, 0.32)

var _vel := Vector2.ZERO
var _damage := 12.0
var _life := LIFETIME


func _ready() -> void:
	add_to_group("action_projectile")  # swept by the room when the fight ends


## Aim + power. Call before adding to the tree.
func setup(dir: Vector2, damage: float) -> void:
	_vel = dir.normalized() * SPEED
	_damage = damage


func _physics_process(delta: float) -> void:
	position += _vel * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("action_enemy"):
		if is_instance_valid(e) and position.distance_to(e.position) <= RADIUS + e.hit_radius:
			e.take_damage(_damage, position)
			queue_free()
			return


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS * 2.3, GLOW)
	draw_circle(Vector2.ZERO, RADIUS, CORE)

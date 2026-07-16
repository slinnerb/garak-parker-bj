extends Node2D
## Floating combat text (Action Arc polish) — a damage number that drifts up and
## fades, then frees itself. Spawned by the room whenever something takes damage.

var _text := ""
var _color := Color.WHITE
var _life := 0.7
const LIFE := 0.7
var _vel := Vector2(0.0, -46.0)


func setup(text: String, color: Color) -> void:
	_text = text
	_color = color


func _physics_process(delta: float) -> void:
	position += _vel * delta
	_vel.y += 36.0 * delta            # ease the rise to a stop
	_life -= delta
	modulate.a = clampf(_life / LIFE, 0.0, 1.0)
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-14, 0), _text, HORIZONTAL_ALIGNMENT_CENTER, 28, 20, _color)

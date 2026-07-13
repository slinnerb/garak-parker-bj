extends Node
## High-level game state (autoload singleton: `GameState`).
##
## Tracks the coarse phase the game is in. This is NOT combat state or run
## state — it is the top-level mode used by scene flow and (later) input
## routing. Detailed state lives in the systems that own it.

enum State {
	BOOT,        ## Initializing services.
	MAIN_MENU,   ## Title screen.
	HUB,         ## Between-life space (future).
	RUN,         ## Inside a life: map/combat/events (future).
	DEATH,       ## Death sequence + Moment of Recall (future).
}

var _state: int = State.BOOT


func current() -> int:
	return _state


func is_state(s: int) -> bool:
	return _state == s


## Transitions to a new state and announces it on the EventBus.
func set_state(new_state: int) -> void:
	if new_state == _state:
		return
	var previous := _state
	_state = new_state
	Log.info(Log.Cat.RUN, "State %s -> %s" % [_name(previous), _name(new_state)])
	EventBus.emit_signal("game_state_changed", previous, new_state)


func _name(s: int) -> String:
	match s:
		State.BOOT: return "BOOT"
		State.MAIN_MENU: return "MAIN_MENU"
		State.HUB: return "HUB"
		State.RUN: return "RUN"
		State.DEATH: return "DEATH"
		_: return "UNKNOWN"

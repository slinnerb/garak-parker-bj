class_name FocusMeter
extends RefCounted
## The freeze-to-plan resource (Action Combat Arc — Phase A). Pure & testable.
##
## Holding "focus" slows the world so you can plan and reposition; it drains a
## meter. When the meter empties you're forced out and must let it recharge past
## a re-engage threshold before focusing again — that recharge window is when
## you're exposed (the core risk/reward). Kept engine-free so the *feel* numbers
## are unit-tested rather than guessed at, matching the project's testable-core
## pattern (pure class + thin node wrapper).

var max_charge: float = 1.0
var drain_per_sec: float = 0.5      # ~2s of focus from full
var regen_per_sec: float = 0.34     # slower than drain — focus is precious
var reengage_fraction: float = 0.3  # must recharge to this before focusing again
var slow_factor: float = 0.22       # world time scale while focusing

var charge: float
var active: bool = false
var _needs_release: bool = false    # set when drained to empty; cleared on release


func _init(p_max: float = 1.0) -> void:
	max_charge = maxf(0.001, p_max)
	charge = max_charge


## Advance one frame. `wants` = the player is holding the focus input this frame.
func update(delta: float, wants: bool) -> void:
	if not wants:
		_needs_release = false      # releasing arms the next focus
	if wants and _can_sustain():
		active = true
		charge = maxf(0.0, charge - drain_per_sec * delta)
		if charge <= 0.0:
			active = false
			_needs_release = true   # forced out: must release before re-engaging
	else:
		active = false
		charge = minf(max_charge, charge + regen_per_sec * delta)


## Can we focus right now? Once active, sustain until empty. Once forced out you
## must release the input AND recharge past the threshold — one burst per press,
## with an exposed recharge window in between.
func _can_sustain() -> bool:
	if charge <= 0.0:
		return false
	if active:
		return true
	if _needs_release:
		return false
	return charge >= reengage_fraction * max_charge


## World time multiplier this frame (1.0 when not focusing).
func time_factor() -> float:
	return slow_factor if active else 1.0


## 0..1 for the HUD bar.
func fraction() -> float:
	return charge / max_charge


## True during the forced recharge (drained and not yet re-engageable) — the
## exposure window the player has to survive on movement alone.
func is_recharging() -> bool:
	return not active and charge < reengage_fraction * max_charge

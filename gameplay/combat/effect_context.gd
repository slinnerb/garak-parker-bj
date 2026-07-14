class_name EffectContext
extends RefCounted
## The environment one card effect executes in (Phase 3 combat).
##
## Bundles everything EffectExecutor needs so effect handlers stay small and
## take a single argument. Built by CombatState for each card play (and reused
## for nested effects), it carries the acting combatant, the resolved targets,
## the card being played (for exhaust/transform self-reference), plus the
## content provider and RNG stream. `combat` is left untyped to avoid a
## class-resolution cycle with CombatState; it is always a CombatState.

var combat                       # CombatState (untyped to avoid a cyclic type ref)
var content                      # content provider with get_def()/has_def()
var rng: RngStream
var source: Combatant
## Combatants the card targets. Untyped Array (elements are Combatant) to avoid
## typed-array covariance friction when retargeting a single enemy.
var targets: Array = []
var card: CardInstance = null


func _init(combat_state, content_provider, rng_stream: RngStream, acting: Combatant, resolved_targets: Array, played_card: CardInstance = null) -> void:
	combat = combat_state
	content = content_provider
	rng = rng_stream
	source = acting
	targets = resolved_targets
	card = played_card


## A shallow copy retargeted to a single combatant — used by random_target so
## nested effects see the chosen target as their target list.
func with_targets(new_targets: Array) -> EffectContext:
	return EffectContext.new(combat, content, rng, source, new_targets, card)

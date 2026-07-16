class_name CardLoadout
extends RefCounted
## The hand plus per-card cooldown state (Action Arc, Phase B). Pure & testable:
## the room drives it, the HUD reads it. Cooldowns tick in real time (even during
## the freeze), so spamming the same card is gated no matter how you plan.

var cards: Array = []   # Array[ActionCard]
var _cd: Array = []     # remaining cooldown seconds, parallel to `cards`


func _init(card_list: Array = []) -> void:
	cards = card_list
	_cd.resize(cards.size())
	_cd.fill(0.0)


func size() -> int:
	return cards.size()


func tick(delta: float) -> void:
	for i in range(_cd.size()):
		_cd[i] = maxf(0.0, _cd[i] - delta)


func is_ready(index: int) -> bool:
	return index >= 0 and index < cards.size() and _cd[index] <= 0.0


## Put a card on cooldown (called when it's actually executed).
func use(index: int) -> void:
	if index >= 0 and index < cards.size():
		_cd[index] = cards[index].cooldown


## 0 (ready) .. 1 (just used) for the HUD cooldown shade.
func cooldown_fraction(index: int) -> float:
	if index < 0 or index >= cards.size():
		return 0.0
	var cd: float = cards[index].cooldown
	return (_cd[index] / cd) if cd > 0.0 else 0.0

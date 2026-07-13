class_name RngStream
extends RefCounted
## A single deterministic random stream.
##
## Thin, testable wrapper around RandomNumberGenerator that adds the helpers
## gameplay actually needs (weighted picks, chances, shuffles). Given the same
## seed and the same sequence of calls, results are identical — this is the
## backbone of reproducible runs (see docs/DECISIONS.md, "Deterministic RNG").

var _rng := RandomNumberGenerator.new()
var _seed: int = 0

func _init(stream_seed: int = 0) -> void:
	set_seed(stream_seed)

func set_seed(stream_seed: int) -> void:
	_seed = stream_seed
	# Assigning `seed` deterministically resets the generator's internal state,
	# so the same seed always replays the same sequence. (Do NOT also zero
	# `state` — that would collapse every seed to the same sequence.)
	_rng.seed = stream_seed

func get_seed() -> int:
	return _seed

## Inclusive integer in [from, to].
func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)

## Float in [0, 1).
func randf() -> float:
	return _rng.randf()

## Float in [from, to].
func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)

## True with probability p (clamped to [0, 1]).
func chance(p: float) -> bool:
	return _rng.randf() < clampf(p, 0.0, 1.0)

## Returns a random element from arr, or null if empty. Does not mutate arr.
func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[_rng.randi_range(0, arr.size() - 1)]

## Weighted pick. items and weights are parallel arrays; returns the chosen
## item, or null if empty / all weights are non-positive.
func pick_weighted(items: Array, weights: Array):
	if items.is_empty() or items.size() != weights.size():
		return null
	var total := 0.0
	for w in weights:
		total += maxf(0.0, float(w))
	if total <= 0.0:
		return null
	var roll := _rng.randf() * total
	var acc := 0.0
	for i in items.size():
		acc += maxf(0.0, float(weights[i]))
		if roll < acc:
			return items[i]
	return items[items.size() - 1]

## Fisher-Yates shuffle in place using this stream (deterministic, unlike
## Array.shuffle() which uses the global RNG).
func shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

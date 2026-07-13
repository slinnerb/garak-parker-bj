extends Node
## Centralized seeded RNG (autoload singleton: `RNG`).
##
## The whole game draws randomness from named streams derived from one master
## seed. Never call the global randi()/randf() in gameplay code — request a
## stream here so runs stay reproducible from a single seed.
##
## Usage:
##   RNG.set_master_seed(12345)
##   var map_rng := RNG.stream(RNG.MAP)
##   var roll := map_rng.randi_range(1, 6)
##
## Each stream is independent: consuming numbers from MAP never shifts COMBAT.

## Well-known stream names. Content can also request arbitrary custom names.
const UNIVERSE := "universe"
const MAP := "map"
const COMBAT := "combat"
const LOOT := "loot"
const EVENT := "event"
const ENEMY := "enemy"
const COSMETIC := "cosmetic"

var _master_seed: int = 0
var _streams: Dictionary = {}  # name -> RngStream


func _ready() -> void:
	# Default to a fixed seed so a fresh boot is deterministic until a run
	# assigns its own. RunManager will call set_master_seed() per life.
	set_master_seed(0)


## Sets the master seed and clears all derived streams so they re-derive.
func set_master_seed(seed_value: int) -> void:
	_master_seed = seed_value
	_streams.clear()
	Log.info(Log.Cat.RNG, "Master seed set to %d" % _master_seed)


func get_master_seed() -> int:
	return _master_seed


## Returns (creating if needed) the deterministic stream for a name.
func stream(name: String) -> RngStream:
	if not _streams.has(name):
		_streams[name] = RngStream.new(_derive_seed(name))
	return _streams[name]


## Convenience: a fresh, independent one-shot seed value (e.g. to seed a run).
## Uses the OS entropy source deliberately — this is the ONE sanctioned place
## to pull non-deterministic randomness, for choosing a brand-new run seed.
func fresh_seed() -> int:
	var r := RandomNumberGenerator.new()
	r.randomize()
	return r.randi()


## Deterministically mixes the master seed with a stream name (FNV-1a style).
## Same (master_seed, name) always yields the same stream seed.
func _derive_seed(name: String) -> int:
	var h: int = _master_seed ^ 0x27d4eb2f165667c5
	for b in name.to_utf8_buffer():
		h = h ^ int(b)
		h = h * 1099511628211  # 64-bit FNV prime; GDScript ints wrap on overflow
	return h

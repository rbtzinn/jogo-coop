extends PhoenixAttack
## Leque de Penas: ela ergue as asas (aviso) e bate; penas de brasa caem girando do alto em duas levas, cada
## uma com um buraco sorteado. Caem em cima das rochas também (param no tampo). Uma pena é turquesa (parry).
## Na fase 3 (`from_sky`) as penas caem sozinhas do céu de cinzas, sem a ave.

const RAISE := 0.6
const FLAP := 0.25
const WAVES := [0.7, 1.6]
const SHIFT := 145.0
const COLUMNS := 6
const SPACING := 290.0
const FIRST_X := 150.0
const FALL := 1.7
const TOP_Y := -70.0
const SWAY := 45.0

@export var from_sky := false

var _gaps: Array[int] = []
var _pink := Vector2i(-1, -1)
var _feathers := {}


func _start() -> void:
	_gaps.clear()
	for w in WAVES.size():
		_gaps.append(rng.randi_range(0, COLUMNS - 1))
	var wave := rng.randi_range(0, WAVES.size() - 1)
	var column := (_gaps[wave] + rng.randi_range(1, COLUMNS - 1)) % COLUMNS
	_pink = Vector2i(wave, column)
	_feathers.clear()


func _tick(t: float) -> void:
	if not from_sky:
		if t < RAISE:
			bird.pose(&"wings", 0)
			bird.shake = 0.3
		elif t < RAISE + FLAP:
			bird.pose(&"wings", 1)
			bird.shake = 0.0
		else:
			bird.pose(&"wings", 3)
	for w in WAVES.size():
		for c in COLUMNS:
			if c == _gaps[w]:
				continue
			var key := w * COLUMNS + c
			var since: float = t - WAVES[w] - c * 0.05
			if since < 0.0:
				continue
			var x := FIRST_X + c * SPACING + (SHIFT if w == 1 else 0.0)
			var ground := surface_y(x)
			if since >= FALL:
				if _feathers.has(key):
					free_prop(_feathers[key])
					_feathers[key] = null
				continue
			if not _feathers.has(key):
				var pink := Vector2i(w, c) == _pink
				_feathers[key] = spawn(&"feather_parry" if pink else &"feather", Vector2(x, TOP_Y), pink, key)
			var feather: PhoenixProp = _feathers[key]
			if feather == null:
				continue
			var u: float = since / FALL
			feather.global_position = Vector2(x + sin(u * TAU * 1.5 + c) * SWAY, lerpf(TOP_Y, ground - 24.0, u))
			feather.spin = sin(u * TAU * 1.5 + c) * 0.6


func _is_done() -> bool:
	return elapsed > WAVES[-1] + COLUMNS * 0.05 + FALL + 0.05

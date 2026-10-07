extends PhoenixAttack
## Anéis de Fogo: o ovo pulsa e brilha (aviso) e solta anéis de fogo que correm pelo chão para os dois lados
## ao mesmo tempo, em três levas: pular por cima (ou ficar numa rocha).

const PULSE := 0.6
const RELEASES := [0.6, 1.5, 2.4]
const RELEASE_POSE := 0.25
const SPEED := 430.0
const START_GAP := 140.0
const LEFT_END := -200.0
const RIGHT_END := 2120.0

var _rings := {}


func _start() -> void:
	_rings.clear()


func _tick(t: float) -> void:
	var releasing := false
	for at: float in RELEASES:
		if t >= at and t < at + RELEASE_POSE:
			releasing = true
	bird.pose(&"egg", 4 if releasing else 3)
	bird.shake = 0.35 if t < PULSE else 0.0
	var center := bird.global_position.x
	for i in RELEASES.size():
		var since: float = t - RELEASES[i]
		if since < 0.0:
			continue
		for side in [-1, 1]:
			var key: int = i * 2 + (0 if side < 0 else 1)
			var x: float = center + side * (START_GAP + SPEED * since)
			if x < LEFT_END or x > RIGHT_END:
				if _rings.has(key):
					free_prop(_rings[key])
					_rings[key] = null
				continue
			if not _rings.has(key):
				_rings[key] = spawn(&"ring", Vector2(x, FLOOR_Y), false, key)
			var ring: PhoenixProp = _rings[key]
			if ring != null:
				ring.global_position.x = x


func _is_done() -> bool:
	return elapsed > RELEASES[-1] + (maxf(RIGHT_END - EGG.x, EGG.x - LEFT_END) - START_GAP) / SPEED + 0.05

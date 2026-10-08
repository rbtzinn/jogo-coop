extends PhoenixAttack
## Anéis de Fogo: o ovo pulsa e brilha (aviso) e solta anéis de fogo que correm pelo chão para os dois lados
## ao mesmo tempo, em quatro levas num ritmo quebrado (duas coladas): pular por cima (ou ficar numa rocha).
## No meio, fagulhas caem do céu onde cada jogador estava (sombra com facho antes), atravessando as rochas:
## pular o anel e sair da coluna ao mesmo tempo.
## args: [x de cada coluna de fagulhas].

const PULSE := 0.6
const RELEASES := [0.6, 1.3, 1.7, 2.6]
const RELEASE_POSE := 0.25
const SPEED := 500.0
const START_GAP := 140.0
const LEFT_END := -200.0
const RIGHT_END := 2120.0
## Fagulhas do céu: quando a sombra aparece, quanto tempo até cair e quanto dura a queda.
const SPARKS_AT := [0.9, 2.0]
const SPARK_MARK := 0.7
const SPARK_FALL := 0.45
const SPARK_TOP := -50.0

var _rings := {}
var _sparks := {}
var _marks := {}


func _start() -> void:
	_rings.clear()
	_sparks.clear()
	_marks.clear()


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
	_tick_sparks(t)


func _tick_sparks(t: float) -> void:
	for w in SPARKS_AT.size():
		for i in args.size():
			# A segunda leva cai um passo ao lado (quem ficou parado depois de desviar da primeira).
			var x: float = clampf(float(args[i]) + (0.0 if w == 0 else (160.0 if i % 2 == 0 else -160.0)), 60.0, 1500.0)
			var key: int = w * 10 + i
			var since: float = t - SPARKS_AT[w]
			if since < 0.0:
				continue
			if since < SPARK_MARK:
				if not _marks.has(key):
					var shadow := LandingShadow.new()
					shadow.radius = Vector2(50, 12)
					shadow.column = true
					add_child(shadow)
					shadow.global_position = Vector2(x, FLOOR_Y - 4.0)
					shadow.reset_physics_interpolation()
					_marks[key] = shadow
				_marks[key].amount = since / SPARK_MARK
				continue
			if _marks.has(key) and _marks[key] != null:
				_marks[key].queue_free()
				_marks[key] = null
			var fall: float = since - SPARK_MARK
			if fall >= SPARK_FALL:
				if _sparks.has(key):
					free_prop(_sparks[key])
					_sparks[key] = null
				continue
			if not _sparks.has(key):
				_sparks[key] = spawn(&"spark", Vector2(x, SPARK_TOP), false, 100 + key)
			var spark: PhoenixProp = _sparks[key]
			if spark != null:
				spark.global_position = Vector2(x, lerpf(SPARK_TOP, FLOOR_Y - 18.0, pow(fall / SPARK_FALL, 1.5)))


func _is_done() -> bool:
	return elapsed > RELEASES[-1] + (maxf(RIGHT_END - EGG.x, EGG.x - LEFT_END) - START_GAP) / SPEED + 0.05

extends PhoenixAttack
## Chuva de Fagulhas: ela solta uma nuvem de cinzas das penas (aviso) e fagulhas caem do céu em colunas, em
## três levas; cada coluna é marcada antes por uma sombra onde vai cair (no chão ou no tampo de uma rocha) e
## cada leva deixa uma coluna livre.

const BURST := 0.5
const WAVES := [0.6, 1.6, 2.6]
const COLUMNS := 7
const FIRST_X := 130.0
const SPACING := 275.0
const MARK := 0.6
const FALL := 0.55
const STREAK := 3
const STREAK_GAP := 0.09
const TOP_Y := -50.0

var _gaps: Array[int] = []
var _sparks := {}
var _marks := {}


func _start() -> void:
	_gaps.clear()
	for w in WAVES.size():
		_gaps.append(rng.randi_range(0, COLUMNS - 1))
	_sparks.clear()
	_marks.clear()


func _tick(t: float) -> void:
	bird.pose(&"perch", 7 if t < BURST + 0.4 else 3)
	bird.shake = 0.3 if t < BURST else 0.0
	for w in WAVES.size():
		for c in COLUMNS:
			if c == _gaps[w]:
				continue
			var x := FIRST_X + c * SPACING + (SPACING * 0.5 if w == 1 else 0.0)
			var ground := surface_y(x)
			var key := w * COLUMNS + c
			var since: float = t - WAVES[w]
			if since < 0.0:
				continue
			# Sombra de aviso, até a última fagulha da coluna chegar.
			var landed := MARK + FALL + STREAK_GAP * (STREAK - 1)
			if since < landed:
				if not _marks.has(key):
					var shadow := LandingShadow.new()
					shadow.radius = Vector2(44, 10)
					add_child(shadow)
					shadow.global_position = Vector2(x, ground - 4.0)
					_marks[key] = shadow
				_marks[key].amount = since / landed
			elif _marks.has(key) and _marks[key] != null:
				_marks[key].queue_free()
				_marks[key] = null
			for s in STREAK:
				var fall: float = since - MARK - s * STREAK_GAP
				var spark_key := key * 10 + s
				if fall < 0.0:
					continue
				if fall >= FALL:
					if _sparks.has(spark_key):
						free_prop(_sparks[spark_key])
						_sparks[spark_key] = null
					continue
				if not _sparks.has(spark_key):
					_sparks[spark_key] = spawn(&"spark", Vector2(x, TOP_Y), false, spark_key)
				var spark: PhoenixProp = _sparks[spark_key]
				if spark != null:
					spark.global_position = Vector2(x, lerpf(TOP_Y, ground - 18.0, pow(fall / FALL, 1.5)))


func _is_done() -> bool:
	return elapsed > WAVES[-1] + MARK + FALL + STREAK_GAP * STREAK + 0.05

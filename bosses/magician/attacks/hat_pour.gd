extends MagicianAttack
## Cartola Despejando (fase 3): o gigante inclina a cartola e despeja uma enxurrada de tralhas
## que caem do teto numa faixa que varre o palco de um lado ao outro (uma sombra no chão
## mostra onde está caindo). Ficar à frente da faixa, ou atravessar com o dash.
## Uma das tralhas é rosa.

const TILT := 0.6
const SWEEP := 3.0
const EVERY := 0.11
const GRAVITY := 1800.0
const START_Y := -60.0
const ENDS := Vector2(260.0, 1660.0)
const SPREAD := 40.0

var _from := 0.0
var _to := 0.0
## Cada tralha: [objeto, tempo em que solta, x, já criada].
var _items: Array = []
var _pink := 0
var _shadow: LandingShadow


func _start() -> void:
	var left_to_right := rng.randf() < 0.5
	_from = ENDS.x if left_to_right else ENDS.y
	_to = ENDS.y if left_to_right else ENDS.x
	_items.clear()
	var count := int(SWEEP / EVERY)
	_pink = rng.randi_range(5, count - 5)
	for k in count:
		var release := TILT + k * EVERY
		var x := lerpf(_from, _to, (release - TILT) / SWEEP) + rng.randf_range(-SPREAD, SPREAD)
		_items.append([null, release, x, false])
	_shadow = LandingShadow.new()
	_shadow.radius = Vector2(90, 16)
	add_child(_shadow)
	_shadow.hide()


func _tick(t: float) -> void:
	var tilt := clampf(t / TILT, 0.0, 1.0) * (0.6 if _to > _from else -0.6)
	if t > TILT + SWEEP:
		tilt *= clampf(1.0 - (t - TILT - SWEEP) / 0.4, 0.0, 1.0)
	boss.giant.hat_tilt = tilt
	boss.giant.laugh = 1.0 if t > TILT and t < TILT + SWEEP else 0.0
	var sweeping := t >= TILT - 0.4 and t < TILT + SWEEP + 0.8
	_shadow.visible = sweeping
	if sweeping:
		var u := clampf((t - TILT + 0.6) / SWEEP, 0.0, 1.0)
		_shadow.global_position = Vector2(lerpf(_from, _to, u), 1000.0)
		_shadow.amount = 1.0
	for k in _items.size():
		var item: Array = _items[k]
		var since: float = t - item[1]
		if since < 0.0:
			break
		if not item[3]:
			item[3] = true
			item[0] = make_prop(&"junk", k == _pink, k)
		var prop: MagicProp = item[0] if is_instance_valid(item[0]) else null
		if prop == null:
			continue
		var y := START_Y + 0.5 * GRAVITY * since * since
		prop.global_position = Vector2(item[2], y)
		if y > 1060.0:
			prop.queue_free()


func _is_done() -> bool:
	return elapsed >= TILT + SWEEP + 1.4


func _stop() -> void:
	boss.giant.hat_tilt = 0.0
	boss.giant.laugh = 0.0
	if is_instance_valid(_shadow):
		_shadow.queue_free()

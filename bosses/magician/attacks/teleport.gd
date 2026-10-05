extends MagicianAttack
## Teleporte (fase 1): uma estrela brilha onde ele vai aparecer (aviso), ele some numa fumaça,
## reaparece lá (no chão ou num pedestal) e solta uma rajada de 8 cartas em círculo.
## Uma das cartas é rosa.

const SPOTS := [Vector2(330, 1000), Vector2(1590, 1000), Vector2(640, 760), Vector2(1280, 760)]
const VANISH := 0.25
const ARRIVE := 0.85
const BURST := 1.3
const BURST_SPEED := 480.0
const POOF := preload("res://components/fx/dust_puff.tscn")

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _star: Node2D
var _arrived := false
var _burst_done := false
var _pink := 0


func _start() -> void:
	_from = boss.zaratan.global_position
	var options: Array = SPOTS.filter(func(spot: Vector2) -> bool: return spot.distance_to(_from) > 200.0)
	_to = options[rng.randi_range(0, options.size() - 1)]
	_pink = rng.randi_range(0, 7)
	_arrived = false
	_burst_done = false
	_star = Node2D.new()
	_star.draw.connect(_draw_star)
	add_child(_star)
	_star.global_position = _to + Vector2(0, -150)
	Fx.spawn(POOF, _from)


func _tick(t: float) -> void:
	var zaratan := boss.zaratan
	if is_instance_valid(_star):
		_star.scale = Vector2.ONE * (0.6 + 0.4 * absf(sin(t * 12.0)))
		_star.queue_redraw()
	if t < ARRIVE:
		zaratan.pose = &"cast"
		zaratan.vanish = clampf(t / VANISH, 0.0, 1.0)
		if t > VANISH * 0.5:
			zaratan.set_present(false)
		return
	if not _arrived:
		_arrived = true
		zaratan.global_position = _to
		zaratan.reset_physics_interpolation()
		zaratan.facing = -1 if _to.x > 960.0 else 1
		Fx.spawn(POOF, _to)
		if is_instance_valid(_star):
			_star.queue_free()
	zaratan.vanish = clampf(1.0 - (t - ARRIVE) / VANISH, 0.0, 1.0)
	if zaratan.vanish < 0.5:
		zaratan.set_present(true)
	if t >= BURST and not _burst_done:
		_burst_done = true
		zaratan.pose = &"throw"
		var center := _to + Vector2(0, -150)
		for i in 8:
			var dir := Vector2.from_angle(TAU * i / 8.0 + 0.2)
			launch(&"card", i == _pink, i, center, dir * BURST_SPEED, 2.4)


func _is_done() -> bool:
	return elapsed >= BURST + 1.6


func _stop() -> void:
	var zaratan := boss.zaratan
	if not _arrived:
		zaratan.global_position = _to
	zaratan.vanish = 0.0
	zaratan.set_present(true)
	zaratan.pose = &"idle"
	if is_instance_valid(_star):
		_star.queue_free()


func _draw_star() -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := 40.0 if i % 2 == 0 else 16.0
		points.append(Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * radius)
	_star.draw_colored_polygon(points, Color("ffe36a"))
	points.append(points[0])
	_star.draw_polyline(points, Color("1b1410"), 4.0)

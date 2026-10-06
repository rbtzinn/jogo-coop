class_name BalloonGhost
extends Enemy
## Baloeiro Assombrado (Trem, vagão BALÕES): fantasma gorducho pendurado num cacho de balões, flutuando por cima
## do vagão e soltando bexigas d'água que caem no teto (a cada quatro, uma rosa para o parry). Tudo segue o
## relógio da fase, igual nos dois PCs. 10 tiros derrubam. Desenho provisório por código (pedido de arte D4
## em docs/prompts/chatgpt_trem_desafiantes.md); a bexiga ainda é a bola do canhão.

const FALL_GRAVITY := 1500.0
## Quanto tempo a bexiga estourada no teto ainda machuca.
const SPLASH_TIME := 0.25
const BODY := Color("e9f0f2")
const BALLOONS := [Color("c8302c"), Color("d9a441"), Color("3f8f8a"), Color("7a3fa0")]

@export var patrol_range := 260.0
@export var drop_period := 1.5
@export var offset := 0.0
## Altura do teto (global) onde as bexigas estouram.
@export var ground_y := 700.0

## Bexigas caindo: número da bexiga -> nó.
var _drops := {}


func _init() -> void:
	max_health = 10
	body_size = Vector2(110, 120)


## Onde ele está no tempo `t` (as bexigas saem de onde ele estava quando soltou).
func float_point(t: float) -> Vector2:
	return home + Vector2(patrol_range * sin(t * 0.55 + offset * TAU), 22.0 * sin(t * 2.1))


func _move(t: float) -> void:
	position = float_point(t)
	var fall := sqrt(2.0 * maxf(ground_y - home.y, 1.0) / FALL_GRAVITY)
	var newest := floori((t - offset) / drop_period)
	var oldest := ceili((t - offset - fall - SPLASH_TIME) / drop_period)
	for k in range(maxi(oldest, 0), newest + 1):
		var drop_time := offset + k * drop_period
		var since := t - drop_time
		if since < 0.0:
			continue
		if not _drops.has(k):
			_drops[k] = _make_drop(k)
		var drop: Node2D = _drops[k]
		if not is_instance_valid(drop):
			continue
		var start := float_point(drop_time) + Vector2(0, 10)
		drop.global_position = Vector2(start.x, minf(start.y + 0.5 * FALL_GRAVITY * since * since, ground_y - 20.0))
		drop.scale = Vector2(1.6, 0.5) if since > fall else Vector2.ONE
	for k in _drops.keys():
		if k < oldest:
			if is_instance_valid(_drops[k]):
				_drops[k].queue_free()
			_drops.erase(k)


func die() -> void:
	super()
	for drop in _drops.values():
		if is_instance_valid(drop):
			drop.queue_free()
	_drops.clear()


func _make_drop(k: int) -> Node2D:
	var drop := ConfettiBall.new()
	drop.pink = k % 4 == 3
	drop.parry_id = "%s:%d" % [parry_id, k]
	drop.top_level = true
	add_child(drop)
	return drop


func _update_art() -> void:
	queue_redraw()


func _draw() -> void:
	var hand := Vector2(30, -110)
	for i in BALLOONS.size():
		var at := hand + Vector2(-60.0 + i * 40.0, -110.0 - (i % 2) * 30.0)
		draw_line(hand, at + Vector2(0, 30), INK, 2.5)
		draw_circle(at, 33.0, INK)
		draw_circle(at, 29.0, BALLOONS[i])
	var body := Vector2(0, -55)
	draw_circle(body, 58.0, INK)
	draw_circle(body, 53.0, BODY)
	draw_circle(body + Vector2(-16, -14), 7.0, INK)
	draw_circle(body + Vector2(12, -14), 7.0, INK)
	draw_arc(body + Vector2(-2, 8), 16.0, 0.3, PI - 0.3, 10, INK, 4.0)
	draw_line(body + Vector2(40, -20), hand, INK, 9.0)

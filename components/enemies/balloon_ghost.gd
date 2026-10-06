class_name BalloonGhost
extends Enemy
## Baloeiro Assombrado (Trem, vagão BALÕES): fantasma gorducho pendurado num cacho de balões, flutuando por cima
## do vagão e soltando bexigas d'água que caem no teto (a cada quatro, uma rosa para o parry). Tudo segue o
## relógio da fase, igual nos dois PCs. 10 tiros derrubam. Desenho do pedido de arte D4
## (docs/prompts/chatgpt_trem_desafiantes.md), recortado por tools/cut_train_challengers.gd.

const FALL_GRAVITY := 1500.0
## Quanto tempo a bexiga estourada no teto ainda machuca.
const SPLASH_TIME := 0.25
const ART := preload("res://components/enemies/art/balloon_ghost.tres")
## O meio do desenho fica acima do ponto dele (o corpo em cima da área que leva tiro, o cacho mais acima).
const ART_CENTER := Vector2(0, -105)

@export var patrol_range := 260.0
@export var drop_period := 1.5
@export var offset := 0.0
## Altura do teto (global) onde as bexigas estouram.
@export var ground_y := 700.0

## Bexigas caindo: número da bexiga -> nó.
var _drops := {}
var _clock := 0.0
var _art := Sprite2D.new()


func _init() -> void:
	max_health = 10
	body_size = Vector2(110, 120)
	death_drawn = true
	death_duration = 0.9


func _ready() -> void:
	super()
	_art.position = ART_CENTER
	add_child(_art)


## Onde ele está no tempo `t` (as bexigas saem de onde ele estava quando soltou).
func float_point(t: float) -> Vector2:
	return home + Vector2(patrol_range * sin(t * 0.55 + offset * TAU), 22.0 * sin(t * 2.1))


func _move(t: float) -> void:
	_clock = t
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
		if since > fall:
			(drop as WaterBalloon).splash()
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
	var drop := WaterBalloon.new()
	drop.pink = k % 4 == 3
	drop.parry_id = "%s:%d" % [parry_id, k]
	drop.top_level = true
	add_child(drop)
	return drop


func _update_art() -> void:
	# Quadros: 0 assobiando, 1 mirando, 2 soltando a bexiga, 3 acenando, 4 sem um balão, 5 sem dois, 6 levou tiro.
	# Quanto mais machucado, menos balões no cacho.
	var index := 0
	var since := fposmod(_clock - offset, drop_period)
	if _flash > 0.25:
		index = 6
	elif since < 0.3:
		index = 2
	elif drop_period - since < 0.45:
		index = 1
	elif health <= max_health * 0.4:
		index = 5
	elif health <= max_health * 0.7:
		index = 4
	else:
		index = 0 if fmod(_clock, 4.0) < 2.6 else 3
	_show(index)


func _update_death(_progress: float) -> void:
	_show(7)


func _show(index: int) -> void:
	ART.show_on(_art, index)
	_art.scale = Vector2.ONE * ART.frame_scale

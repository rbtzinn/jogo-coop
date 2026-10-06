class_name SpringAcrobat
extends Enemy
## Saltimbanco de Mola (Trem, vagão ACROBATAS): fantasma de acrobata num pula-pula de mola que salta por cima
## do vagão parando em três pontos (esquerda, meio, direita, meio...). No alto dá para passar por baixo dele;
## ao cair, solta uma onda rente ao teto para os dois lados (pular por cima). 10 tiros derrubam.
## Desenho provisório por código (pedido de arte D1 em docs/prompts/chatgpt_trem_desafiantes.md).

## Duração de cada salto (voo + tempo no chão) e a parte dele no ar.
const HOP_TIME := 1.6
const AIR_PART := 0.75
const HOP_HEIGHT := 330.0
## Onda do pouso: até onde vai para cada lado e o tamanho.
const WAVE_REACH := 300.0
const WAVE_SIZE := Vector2(46, 38)
const STRIPE := Color("c8302c")
const CREAM := Color("f2e6cc")
const BRASS := Color("d9a441")

@export var patrol_range := 280.0
@export var offset := 0.0

var _facing := -1.0
## Fração do salto (0 a 1) e quanto a mola está apertada (0 a 1).
var _hop := 0.0
var _squash := 0.0
## Quanto a onda já andou (0 a 1), ou -1 sem onda.
var _wave := -1.0
var _waves: Array[EnemyHitbox] = []


func _init() -> void:
	max_health = 10
	body_size = Vector2(70, 120)


func _ready() -> void:
	super()
	for side in 2:
		var wave := EnemyHitbox.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = WAVE_SIZE
		shape.shape = rect
		shape.position = Vector2(0, -WAVE_SIZE.y * 0.5)
		wave.add_child(shape)
		wave.active = false
		add_child(wave)
		_waves.append(wave)


func _move(t: float) -> void:
	var stops := [-patrol_range, 0.0, patrol_range, 0.0]
	var cycle := (t + offset * HOP_TIME) / HOP_TIME
	var n := floori(cycle)
	var u := cycle - n
	var from: float = stops[n % 4]
	var to: float = stops[(n + 1) % 4]
	_facing = signf(to - from) if to != from else _facing
	if u < AIR_PART:
		_hop = u / AIR_PART
		_squash = 0.0
		_wave = -1.0
		position = home + Vector2(lerpf(from, to, _hop), -HOP_HEIGHT * 4.0 * _hop * (1.0 - _hop))
	else:
		var ground := (u - AIR_PART) / (1.0 - AIR_PART)
		_hop = 1.0
		_squash = 1.0 - ground
		_wave = ground
		position = home + Vector2(to, 0)
	for side in 2:
		var wave := _waves[side]
		wave.active = _wave >= 0.0 and not dead
		wave.visible = wave.active
		if wave.active:
			wave.position = Vector2((40.0 + WAVE_REACH * _wave) * (1 if side == 0 else -1), 0)


func die() -> void:
	super()
	for wave in _waves:
		wave.active = false
		wave.hide()


func _update_art() -> void:
	queue_redraw()


func _draw() -> void:
	# Mola em zigue-zague, do chão até os pés.
	var spring_height := 40.0 - 22.0 * _squash
	var points := PackedVector2Array()
	for i in 7:
		points.append(Vector2(-12.0 if i % 2 == 0 else 12.0, -spring_height * i / 6.0))
	draw_polyline(points, INK, 9.0)
	draw_polyline(points, BRASS, 4.5)
	var hips := Vector2(0, -spring_height - 6.0)
	var body := Rect2(hips + Vector2(-20, -62), Vector2(40, 62))
	draw_rect(body.grow(4), INK)
	draw_rect(body, CREAM)
	for i in 4:
		draw_rect(Rect2(body.position + Vector2(0, 6 + i * 15), Vector2(40, 7)), STRIPE)
	var head := hips + Vector2(0, -88)
	draw_circle(head, 25.0, INK)
	draw_circle(head, 21.0, CREAM)
	# Olhos e boca virados para onde ele vai.
	draw_circle(head + Vector2(_facing * 8.0 - 5.0, -4), 4.0, INK)
	draw_circle(head + Vector2(_facing * 8.0 + 5.0, -4), 4.0, INK)
	draw_arc(head + Vector2(_facing * 6.0, 6), 8.0, 0.2, PI - 0.2, 8, INK, 3.0)
	draw_rect(Rect2(head + Vector2(-10, -32), Vector2(20, 10)), STRIPE)
	for side in 2:
		var wave := _waves[side]
		if wave.visible:
			var fade := 1.0 - _wave
			draw_arc(wave.position + Vector2(0, -4), 26.0, PI, TAU, 10, Color(CREAM, fade), 8.0)
			draw_arc(wave.position + Vector2(0, -4), 26.0, PI, TAU, 10, Color(INK, fade * 0.6), 2.0)

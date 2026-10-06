class_name SpringAcrobat
extends Enemy
## Saltimbanco de Mola (Trem, vagão ACROBATAS): fantasma de acrobata num pula-pula de mola que salta por cima
## do vagão parando em três pontos (esquerda, meio, direita, meio...). No alto dá para passar por baixo dele;
## ao cair, solta uma onda rente ao teto para os dois lados (pular por cima). 10 tiros derrubam.
## Desenho do pedido de arte D1 (docs/prompts/chatgpt_trem_desafiantes.md), recortado por
## tools/cut_train_challengers.gd.

## Duração de cada salto (voo + tempo no chão) e a parte dele no ar.
const HOP_TIME := 1.6
const AIR_PART := 0.75
const HOP_HEIGHT := 330.0
## Onda do pouso: até onde vai para cada lado e o tamanho.
const WAVE_REACH := 300.0
const WAVE_SIZE := Vector2(46, 38)
const ART := preload("res://components/enemies/art/spring_acrobat.tres")
const SHOCK := preload("res://components/enemies/art/shockwave.tres")

@export var patrol_range := 280.0
@export var offset := 0.0

var _facing := -1.0
## Fração do salto (0 a 1) e quanto a mola está apertada (0 a 1).
var _hop := 0.0
var _squash := 0.0
## Quanto a onda já andou (0 a 1), ou -1 sem onda.
var _wave := -1.0
var _waves: Array[EnemyHitbox] = []
var _art := Sprite2D.new()
var _shock := Sprite2D.new()


func _init() -> void:
	max_health = 10
	body_size = Vector2(80, 150)
	death_drawn = true
	death_duration = 0.8


func _ready() -> void:
	super()
	add_child(_shock)
	add_child(_art)
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
	# Quadros: 0 mola apertada, 1 saindo, 2 cambalhota no alto, 3 caindo, 4 pouso, 5 balançando, 6 levou tiro.
	var index := 0
	if _flash > 0.25:
		index = 6
	elif _wave < 0.0:
		index = 1 if _hop < 0.15 else (2 if _hop < 0.6 else 3)
	else:
		index = 4 if _wave < 0.35 else (5 if _wave < 0.7 else 0)
	_show(ART, index)
	_update_shockwave()


func _update_death(progress: float) -> void:
	_show(ART, 7)
	_shock.hide()


## O desenho olha para a esquerda; vira quando ele vai para a direita.
func _show(animation: FrameAnimation, index: int) -> void:
	animation.show_on(_art, index)
	_art.scale = Vector2(animation.frame_scale * -_facing, animation.frame_scale)


## A onda é um anel de poeira que cresce do ponto do pouso até onde vão as áreas que machucam.
func _update_shockwave() -> void:
	_shock.visible = _wave >= 0.0 and not dead
	if not _shock.visible:
		return
	var index := mini(int(_wave * SHOCK.frame_count()), SHOCK.frame_count() - 1)
	SHOCK.show_on(_shock, index)
	var width := 2.0 * (40.0 + WAVE_REACH * _wave) + WAVE_SIZE.x
	_shock.scale = Vector2(width / SHOCK.frames[index].get_width(), SHOCK.frame_scale)

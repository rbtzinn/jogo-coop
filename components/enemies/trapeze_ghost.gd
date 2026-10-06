class_name TrapezeGhost
extends Enemy
## Trapezista do Além (Trem, vagão TRAPÉZIO): fantasma pendurada de cabeça para baixo num trapézio que balança
## por cima do vagão pelo relógio da fase. No ponto mais baixo ela passa na altura da cabeça de quem está em
## pé: abaixar (ou pular por cima dela nas pontas do balanço). 8 tiros derrubam. O ponto onde ela é colocada é
## onde as mãos dela passam no ponto mais baixo; o nó inteiro gira com as cordas (as áreas de dano também).
## Desenho do pedido de arte D2 (docs/prompts/chatgpt_trem_desafiantes.md), recortado por
## tools/cut_train_challengers.gd com a âncora na barra.

const ART := preload("res://components/enemies/art/trapeze_ghost.tres")
const ROPE := Color("c9b48a")
## Distância entre as cordas na barra e lá em cima.
const ROPE_SPREAD := 46.0
const ROPE_TOP_SPREAD := 20.0

## Comprimento das cordas (do ponto de cima até as mãos), ângulo máximo, duração de uma ida e volta e atraso
## (fração).
@export var length := 430.0
@export var amplitude := 1.0
@export var period := 2.8
@export var offset := 0.0

var _pivot := Vector2.ZERO
## Fase do balanço (radianos) e o ângulo das cordas.
var _phase := 0.0
var _angle := 0.0
var _art := Sprite2D.new()


func _init() -> void:
	max_health = 8
	body_size = Vector2(90, 170)
	death_drawn = true
	death_duration = 0.8


func _ready() -> void:
	super()
	_pivot = home - Vector2(0, length)
	_art.position = Vector2(0, -body_size.y)
	add_child(_art)


func _move(t: float) -> void:
	_phase = TAU * (t / period + offset)
	_angle = amplitude * sin(_phase)
	position = _pivot + Vector2(sin(_angle), cos(_angle)) * length
	rotation = -_angle


func _update_art() -> void:
	# Quadros: 0 voltando, 1 embaixo pegando, 2 indo, 3 na ponta entediada, 4 rasante gritando, 5 beijinho,
	# 6 levou tiro.
	var index := 0
	var swing := sin(_phase)
	var going := cos(_phase) > 0.0
	if _flash > 0.25:
		index = 6
	elif absf(swing) > 0.85:
		# Na ponta do balanço: de cada dois, um beijinho.
		index = 5 if posmod(floori(_phase / PI + 0.5), 4) < 2 else 3
	elif absf(swing) < 0.35:
		index = 4 if going else 1
	else:
		index = 2 if going else 0
	ART.show_on(_art, index)
	_art.scale = Vector2.ONE * ART.frame_scale
	queue_redraw()


func _update_death(_progress: float) -> void:
	ART.show_on(_art, 7)
	_art.scale = Vector2.ONE * ART.frame_scale


func _draw() -> void:
	var top := Vector2(0, -length)
	for side in [-1.0, 1.0]:
		var bar := Vector2(side * ROPE_SPREAD, -body_size.y)
		draw_line(top + Vector2(side * ROPE_TOP_SPREAD, 0), bar, INK, 8.0)
		draw_line(top + Vector2(side * ROPE_TOP_SPREAD, 0), bar, ROPE, 4.5)

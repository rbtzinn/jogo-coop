class_name LanternGhost
extends Enemy
## Sombra do Lanterninha (Trem, vagão FANTASMAS): fantasma de lanterninha de teatro que anda de um lado para
## o outro em cima do vagão. Com a lanterna acesa ele é sólido e leva tiro; com ela apagada vira uma sombra
## que os tiros atravessam, mas que continua machucando quem encosta. Tudo pelo relógio da fase. 6 tiros
## derrubam. Desenho do pedido de arte D5 (docs/prompts/chatgpt_trem_desafiantes.md), recortado por
## tools/cut_train_challengers.gd. Os quadros da sombra vieram quase opacos: o jogo os deixa transparentes.

const ART := preload("res://components/enemies/art/lantern_ghost.tres")
## Ciclo da lanterna: acesa durante LIT_TIME, apagada no resto.
const CYCLE := 3.4
const LIT_TIME := 2.0
## Quanto tempo leva sumindo e voltando (o desenho meio transparente).
const FADE_TIME := 0.35
## Opacidade da sombra e de quem está sumindo.
const SHADOW_ALPHA := 0.35
const FADING_ALPHA := 0.65

@export var patrol_range := 200.0
@export var speed := 120.0
@export var offset := 0.0

var _facing := -1.0
var _lit := true
## Onde está no ciclo da lanterna (s).
var _cycle_time := 0.0
var _art := Sprite2D.new()


func _init() -> void:
	max_health = 6
	body_size = Vector2(70, 190)
	death_drawn = true
	death_duration = 0.9


func _ready() -> void:
	super()
	add_child(_art)


func _move(t: float) -> void:
	var cycle := 4.0 * patrol_range / speed
	var u := fmod(t + offset * cycle, cycle) / cycle
	var x := -patrol_range + 4.0 * patrol_range * u if u < 0.5 else 3.0 * patrol_range - 4.0 * patrol_range * u
	_facing = 1.0 if u < 0.5 else -1.0
	position = home + Vector2(x, 0)
	_cycle_time = fmod(t + offset * CYCLE, CYCLE)
	var lit := _cycle_time < LIT_TIME
	if lit != _lit:
		_lit = lit
		hurtbox.set_deferred(&"monitorable", lit and not dead)


func _update_art() -> void:
	# Quadros: 0 andando de lanterna erguida, 1 girando a lanterna, 2 pedindo silêncio, 3 lanterna piscando,
	# 4 sumindo, 5 só a sombra, 6 levou tiro.
	var index := 0
	var alpha := 1.0
	if _flash > 0.25:
		index = 6
	elif _lit:
		if _cycle_time < 0.9:
			index = 0
		elif _cycle_time < 1.3:
			index = 1
		elif _cycle_time < LIT_TIME - 0.4:
			index = 2
		else:
			index = 3
	else:
		var dark := _cycle_time - LIT_TIME
		var fading := dark < FADE_TIME or dark > CYCLE - LIT_TIME - FADE_TIME
		index = 4 if fading else 5
		alpha = FADING_ALPHA if fading else SHADOW_ALPHA
	modulate.a *= alpha
	_show(index)


func _update_death(_progress: float) -> void:
	_show(7)


## O desenho olha para a esquerda; vira quando ele anda para a direita.
func _show(index: int) -> void:
	ART.show_on(_art, index)
	_art.scale = Vector2(ART.frame_scale * -_facing, ART.frame_scale)

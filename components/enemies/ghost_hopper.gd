class_name GhostHopper
extends Enemy
## Palhacinho-fantasma que vai e volta pulando em cima de um vagão. Encostar machuca; 4 tiros
## derrubam. Desenho em quadros: agachado, subindo, no alto e caindo; derrotado, murcha num lençol.

const HOP := preload("res://components/enemies/art/ghost_hop.tres")
const DEFEAT := preload("res://components/enemies/art/ghost_defeat.tres")

## Até onde vai para cada lado a partir de onde foi colocado.
@export var patrol_range := 200.0
@export var speed := 170.0
## Atraso na patrulha (para dois fantasmas não andarem iguais).
@export var offset := 0.0

var _facing := 1.0
var _hop := 0.0
## Subindo no pulo (para escolher o quadro).
var _rising := true
var _art := Sprite2D.new()


func _init() -> void:
	max_health = 4
	body_size = Vector2(64, 86)
	death_drawn = true
	death_duration = 0.6


func _ready() -> void:
	super()
	add_child(_art)


func _move(t: float) -> void:
	# Vai e volta com velocidade constante (onda triangular).
	var cycle := 4.0 * patrol_range / speed
	var u := fmod(t + offset * cycle, cycle) / cycle
	var x := -patrol_range + 4.0 * patrol_range * u if u < 0.5 else 3.0 * patrol_range - 4.0 * patrol_range * u
	_facing = 1.0 if u < 0.5 else -1.0
	_hop = absf(sin(t * 7.0))
	_rising = sin(t * 7.0) * cos(t * 7.0) > 0.0
	position = home + Vector2(x, -_hop * 28.0)


func _update_art() -> void:
	# No chão: agachado (antes de sair) ou caindo no pouso; no ar: subindo ou no alto.
	var index := 0
	if _hop > 0.8:
		index = 2
	elif _hop > 0.25:
		index = 1 if _rising else 2
	else:
		index = 0 if _rising else 3
	_show(HOP, index)


func _update_death(progress: float) -> void:
	_show(DEFEAT, mini(int(progress * 5.0), DEFEAT.frame_count() - 1))


func _show(animation: FrameAnimation, index: int) -> void:
	animation.show_on(_art, index)
	_art.scale = Vector2(animation.frame_scale * _facing, animation.frame_scale)

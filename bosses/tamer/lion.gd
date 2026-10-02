class_name TamerLion
extends Node2D
## Leopoldo, o leão. Fica sentado no pedestal respirando; os ataques movem ele
## (pulo pelas argolas) e abrem a boca (rugido).

@export var breathe_speed := 1.6

## Onde ele fica sentado (posição global, definida ao entrar na cena).
var home_position := Vector2.ZERO
## Controlado pelos ataques: quando falso, a respiração não mexe no corpo.
var idle := true

var _time := 0.0
var _flash := 0.0

@onready var body: Node2D = $Body
@onready var head_closed: Sprite2D = $Body/Head
@onready var head_open: Sprite2D = $Body/HeadRoar


func _ready() -> void:
	home_position = global_position
	set_roaring(false)


func _process(delta: float) -> void:
	_time += delta
	if idle:
		body.scale = Vector2(1.0, 1.0 + sin(_time * breathe_speed * TAU) * 0.015)
	_flash = maxf(_flash - delta * 6.0, 0.0)
	modulate = Color(1.0 + _flash, 1.0 + _flash * 0.8, 1.0 + _flash * 0.6)


func set_roaring(roaring: bool) -> void:
	head_closed.visible = not roaring
	head_open.visible = roaring


## Clarão rápido ao levar tiro.
func flash() -> void:
	_flash = 0.5


func go_home() -> void:
	global_position = home_position
	rotation = 0.0
	body.scale = Vector2.ONE
	body.position = Vector2.ZERO
	idle = true
	visible = true
	set_roaring(false)

class_name Unicycle
extends Node2D
## Monociclo gigante da fase 3, em duas peças desenhadas (recortadas por tools/cut_unicycle_parts.gd): a roda,
## que gira conforme anda, e a armação (garfo, haste, pedais e selim) na frente dela. O ponto do nó é
## onde a roda toca o chão. A roda machuca e os irmãos em cima também. A roda passa por baixo da tábua pendurada
## (216 px), mas desde 05/10/2026 o selim fica baixo o bastante para os irmãos pegarem quem está em cima dela
## (pedido do usuário: a tábua era um lugar seguro demais). O desvio seguro é o dash; pular a roda do chão fica
## arriscado.

const WHEEL_TEXTURE := preload("res://bosses/jugglers/art/unicycle/wheel.png")
const FRAME_TEXTURE := preload("res://bosses/jugglers/art/unicycle/frame.png")
## Centro da textura da armação em relação ao eixo (pixels de jogo).
const FRAME_CENTER := Vector2(3.2, -107.9)
const WHEEL_RADIUS := 110.0
## Altura do selim acima do chão (os irmãos ficam em cima dele).
const SEAT_HEIGHT := 330.0

## Ângulo da roda (gira conforme anda).
var roll := 0.0
var _last_x := 0.0
var _wheel := Sprite2D.new()

@onready var hitbox: EnemyHitbox = $Hitbox


func _ready() -> void:
	_last_x = global_position.x
	var hub := Vector2(0, -WHEEL_RADIUS)
	_wheel.texture = WHEEL_TEXTURE
	_wheel.scale = Vector2.ONE * 0.5
	_wheel.position = hub
	add_child(_wheel)
	var frame := Sprite2D.new()
	frame.texture = FRAME_TEXTURE
	frame.scale = Vector2.ONE * 0.5
	frame.position = hub + FRAME_CENTER
	add_child(frame)


func _physics_process(_delta: float) -> void:
	roll += (global_position.x - _last_x) / WHEEL_RADIUS
	_last_x = global_position.x
	_wheel.rotation = roll


func seat_position() -> Vector2:
	return global_position + Vector2(0, -SEAT_HEIGHT)

class_name Unicycle
extends Node2D
## Monociclo gigante da fase 3 (desenhado por código; os irmãos em cima têm desenho próprio). O ponto do nó é
## onde a roda toca o chão. A roda machuca e os irmãos em cima também. A roda passa por baixo da tábua pendurada
## (216 px), mas desde 05/10/2026 o selim fica baixo o bastante para os irmãos pegarem quem está em cima dela
## (pedido do usuário: a tábua era um lugar seguro demais). O desvio seguro é o dash; pular a roda do chão fica
## arriscado.

const INK := Color("1b1410")
const WHEEL_RADIUS := 110.0
## Altura do selim acima do chão (os irmãos ficam em cima dele).
const SEAT_HEIGHT := 330.0
## Altura dos pedais abaixo do selim (monociclo girafa, com corrente até a roda).
const CRANK_BELOW_SEAT := 45.0

## Ângulo da roda (gira conforme anda).
var roll := 0.0
var _last_x := 0.0

@onready var hitbox: EnemyHitbox = $Hitbox


func _ready() -> void:
	_last_x = global_position.x


func _physics_process(_delta: float) -> void:
	roll += (global_position.x - _last_x) / WHEEL_RADIUS
	_last_x = global_position.x
	queue_redraw()


func seat_position() -> Vector2:
	return global_position + Vector2(0, -SEAT_HEIGHT)


func _draw() -> void:
	var hub := Vector2(0, -WHEEL_RADIUS)
	# Garfo e haste até o selim.
	draw_line(hub, Vector2(0, -SEAT_HEIGHT + 10), INK, 14.0)
	draw_line(hub, Vector2(0, -SEAT_HEIGHT + 10), Color("b0b0b8"), 8.0)
	draw_rect(Rect2(-40, -SEAT_HEIGHT - 4, 80, 18), INK)
	draw_rect(Rect2(-36, -SEAT_HEIGHT, 72, 10), Color("6e1c1b"))
	# Roda com raios girando.
	draw_circle(hub, WHEEL_RADIUS, INK)
	draw_circle(hub, WHEEL_RADIUS - 8, Color("c8302c"))
	draw_circle(hub, WHEEL_RADIUS - 22, Color("f2e6cc"))
	for i in 8:
		var a := roll + TAU * i / 8.0
		draw_line(hub, hub + Vector2.from_angle(a) * (WHEEL_RADIUS - 22), INK, 4.0)
	draw_circle(hub, 14, INK)
	# Monociclo girafa: os pedais ficam lá em cima, perto dos pés de quem pedala (o desenho dos irmãos tem os
	# sapatos a uns 40 px do selim), e uma corrente leva o giro até a roda.
	var crank := Vector2(0, -SEAT_HEIGHT + CRANK_BELOW_SEAT)
	for side in [-1.0, 1.0]:
		draw_line(crank + Vector2(side * 9, 0), hub + Vector2(side * 9, 0), INK, 3.0)
	draw_circle(crank, 12, INK)
	draw_circle(crank, 8, Color("c9a03c"))
	for side in [-1.0, 1.0]:
		var pedal := crank + Vector2.from_angle(roll * 2.0 + (0.0 if side > 0 else PI)) * 22
		draw_line(crank, pedal, INK, 6.0)
		draw_rect(Rect2(pedal - Vector2(10, 4), Vector2(20, 8)), INK)

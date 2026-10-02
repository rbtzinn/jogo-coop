class_name Unicycle
extends Node2D
## Monociclo gigante da fase 3 (desenhado por código). O ponto do nó é onde a roda toca o
## chão. Só a roda machuca; entre a roda e o selim fica um vão onde cabe quem está num
## pedestal (o monociclo passa por baixo dele).

const INK := Color("1b1410")
const WHEEL_RADIUS := 110.0
## Altura do selim acima do chão (os irmãos ficam em cima dele).
const SEAT_HEIGHT := 380.0

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
	# Pedais girando junto.
	for side in [-1.0, 1.0]:
		var pedal := hub + Vector2.from_angle(roll * 1.0 + (0.0 if side > 0 else PI)) * 34
		draw_line(hub, pedal, INK, 6.0)
		draw_rect(Rect2(pedal - Vector2(12, 4), Vector2(24, 8)), INK)

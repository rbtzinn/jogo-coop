class_name ParryFlash
extends Node2D
## Estouro rosa do parry: anel e estrelinhas saindo do ponto. Sempre aparece (mesmo na
## qualidade baixa), porque avisa o jogador que o parry deu certo.

const PINK := Color("ff5fa2")
const LIGHT := Color("ffd1e6")
const DURATION := 0.4

var size := 1.0
var _time := 0.0


static func spawn(at: Vector2, scale_factor := 1.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var flash := ParryFlash.new()
	flash.size = scale_factor
	tree.current_scene.add_child(flash)
	flash.global_position = at
	flash.z_index = 50


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _time / DURATION
	var radius := (30.0 + 90.0 * ease(k, 0.4)) * size
	var alpha := 1.0 - k
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(PINK, alpha), 10.0 * (1.0 - k) + 2.0, true)
	draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 32, Color(LIGHT, alpha), 4.0, true)
	for i in 8:
		var direction := Vector2.from_angle(TAU * i / 8.0 + 0.3)
		var at := direction * radius * 1.15
		_draw_star(at, 10.0 * size * (1.0 - k * 0.5), Color(LIGHT if i % 2 == 0 else PINK, alpha))


func _draw_star(at: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := r if i % 2 == 0 else r * 0.45
		points.append(at + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * radius)
	draw_colored_polygon(points, color)

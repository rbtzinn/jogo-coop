class_name SmokeDecoy
extends Node2D
## Boneco de fumaça deixado pela Fumaça do Mágico: uma silhueta cinza que se desfaz.

var duration := 1.0
var _time := 0.0


static func spawn(at: Vector2, life: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var decoy := SmokeDecoy.new()
	decoy.duration = life
	tree.current_scene.add_child(decoy)
	decoy.global_position = at
	decoy.z_index = 5


func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _time / duration
	var color := Color(0.75, 0.72, 0.8, 0.7 * (1.0 - k))
	var drift := Vector2(0, -20.0 * k)
	for blob in [[Vector2(0, -20), 30.0], [Vector2(0, -62), 34.0], [Vector2(0, -108), 26.0], [Vector2(-26, -70), 16.0],
			[Vector2(26, -70), 16.0]]:
		draw_circle(blob[0] + drift + Vector2(sin(_time * 6.0 + blob[1]) * 4.0, 0), blob[1] * (1.0 + k * 0.4), color)

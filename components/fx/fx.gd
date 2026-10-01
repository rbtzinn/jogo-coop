class_name Fx
## Cria efeitos visuais passageiros (faíscas, poeira), respeitando a qualidade gráfica.


static func spawn(scene: PackedScene, at: Vector2, angle := 0.0) -> void:
	if Settings.quality == Settings.Quality.LOW:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var effect: Node2D = scene.instantiate()
	tree.current_scene.add_child(effect)
	effect.global_position = at
	effect.rotation = angle
	effect.reset_physics_interpolation()

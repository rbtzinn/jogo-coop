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


## Toca uma vez um desenho quadro a quadro (ex.: o acerto do tiro). `size` multiplica o tamanho
## do desenho; com `fade_last`, o último quadro some aos poucos.
static func burst(animation: FrameAnimation, at: Vector2, angle := 0.0, fps := 14.0, size := 1.0,
		fade_last := true) -> void:
	if Settings.quality == Settings.Quality.LOW:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var effect := FrameBurst.new()
	effect.animation = animation
	effect.fps = fps
	effect.fade_last = fade_last
	effect.position = at
	effect.rotation = angle
	effect.scale = Vector2.ONE * size
	effect.z_index = 40
	# Pode nascer no meio de uma colisão: entra na cena no fim do quadro.
	tree.current_scene.add_child.call_deferred(effect)

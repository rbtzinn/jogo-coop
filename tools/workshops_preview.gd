extends Node
## Capturas da área e do voo, com save isolado; não é gameplay manual.

func _ready() -> void:
	_move.call_deferred()


func _move() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func wait() -> void:
	await get_tree().create_timer(0.5).timeout


func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/qa/workshops/" + label + ".png")


func _run() -> void:
	SaveGame.path = "user://workshops_preview.json"
	SaveGame.reset()
	PlayerSpawner.solo_slot = 0
	get_tree().change_scene_to_file(Levels.TRAVEL)
	await wait()
	get_tree().current_scene._end_flight()
	await wait()
	await shot("flight_menu")
	get_tree().current_scene.fly_to(3)
	await wait()
	var map: PaintedWorld = get_tree().current_scene
	var walker: WorldWalker = get_tree().get_first_node_in_group(&"walkers")
	await shot("arrival")
	for probe: Array in [["theater_foreground",Vector2(1235,642)],
		["warehouse_foreground",Vector2(1068,508)]]:
		walker.global_position = map.nearest_walkable(map.pixel_to_world(probe[1])) + Vector3(0,0.4,0)
		walker.velocity = Vector3.ZERO
		walker.reset_physics_interpolation()
		map._focus = map._target_focus()
		map._update_camera(1.0)
		await wait()
		await shot(probe[0])
	for name in ["DoorCarretel", "DoorCounterweight", "DoorMaestro", "DoorTheater", "DoorScenery", "DoorShop"]:
		var door: WorldDoor = map.get_node(name)
		walker.global_position = door.front_point() + Vector3(0, 0.4, 0)
		walker.velocity = Vector3.ZERO
		walker.reset_physics_interpolation()
		map._focus = map._target_focus()
		map._update_camera(1.0)
		await wait()
		await shot(name)
	map.get_node("DoorShop").try_enter(walker)
	await wait()
	await shot("shop")
	(get_tree().get_first_node_in_group(&"blocking_ui") as ShopPanel).close()
	map.get_node("DoorDressing").try_enter(walker)
	await wait()
	await shot("dressing")
	PauseMenu.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()

extends Node
## Percorre as trilhas com os controles reais, sem teletransportar o personagem.
var failures := 0

func _ready() -> void:
	_move.call_deferred()

func _move() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()

func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func release() -> void:
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)

func cell_at(grid: AStarGrid2D, pixel: Vector2) -> Vector2i:
	var origin := Vector2i(pixel / 8.0)
	for radius in range(0, 10):
		for y in range(-radius, radius+1):
			for x in range(-radius, radius+1):
				var cell := origin + Vector2i(x,y)
				if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
					return cell
	return origin

func _run() -> void:
	get_tree().create_timer(120.0, true, false, true).timeout.connect(func() -> void: get_tree().quit(99))
	SaveGame.path = "user://test_workshops_walk.json"
	SaveGame.reset()
	PlayerSpawner.solo_slot = 0
	Levels.return_door = "plane"
	get_tree().change_scene_to_file(Levels.MAPS[3])
	await frames(20)
	var map: PaintedWorld = get_tree().current_scene
	var walker: WorldWalker = get_tree().get_first_node_in_group(&"walkers")
	var obstacle: PaintedObstacle = map.get_node("PlaneObstacle")
	check(obstacle.get_child_count() == 1 and obstacle.collision_layer == 1, "plane has solid physical collision")
	check(not map.is_walkable(map.pixel_to_world(Vector2(320,650))), "plane footprint excluded from walking surface")
	var landing := walker.global_position
	# Encosta na lateral do corpo; no ponto de embarque (canto inferior) pode
	# deslizar corretamente para contornar o avião, e isso não é atravessá-lo.
	walker.global_position = map.pixel_to_world(Vector2(420,650)) + Vector3(0,0.4,0)
	walker.velocity = Vector3.ZERO
	await frames(5)
	Input.action_press(&"move_left")
	await frames(100)
	release()
	await frames(10)
	check(map.world_to_pixel(walker.global_position).x >= 398,
		"walking left cannot pass through plane (at %s)" % map.world_to_pixel(walker.global_position))
	for case: Array in [[Vector2(220,650), &"move_right"],
		[Vector2(320,590), &"move_down"], [Vector2(320,725), &"move_up"]]:
		walker.global_position = map.pixel_to_world(case[0]) + Vector3(0,0.4,0)
		walker.velocity = Vector3.ZERO
		await frames(5)
		Input.action_press(case[1])
		await frames(100)
		release()
		await frames(5)
		var pixel := map.world_to_pixel(walker.global_position)
		var stopped := pixel.x <= 240 if case[1] == &"move_right" else (pixel.y <= 617 if case[1] == &"move_down" else pixel.y >= 691)
		check(stopped, "plane blocks %s (at %s)" % [case[1],pixel])
	walker.global_position = landing
	walker.velocity = Vector3.ZERO
	await frames(5)
	# Escada apontada pelo usuário: caminho direto cais→pátio, sem volta pela ilha.
	var stairs := [Vector2(450,680), Vector2(485,656), Vector2(510,634),
		Vector2(535,615), Vector2(559,590), Vector2(578,565), Vector2(610,551)]
	var gaps := 0
	for i in stairs.size()-1:
		for sample in 21:
			if not map.is_walkable(map.pixel_to_world(stairs[i].lerp(stairs[i+1], sample/20.0))):
				gaps += 1
	check(gaps == 0, "dock staircase continuous (%d gaps)" % gaps)
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, 209, 118)
	grid.cell_size = Vector2(8, 8)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in 118:
		for x in 209:
			grid.set_point_solid(Vector2i(x,y), not map.is_walkable(map.pixel_to_world(Vector2(x,y)*8.0)))
	for door_name in ["DoorScenery", "DoorShop", "DoorDressing", "DoorTheater", "DoorMaestro", "DoorCounterweight", "DoorCarretel", "DoorPlane"]:
		var door: WorldDoor = map.get_node(door_name)
		var route := grid.get_point_path(cell_at(grid,map.world_to_pixel(walker.global_position)), cell_at(grid,door.painted_front))
		check(not route.is_empty(), door_name + " connected to current location")
		if door_name == "DoorScenery":
			var length := 0.0
			for i in route.size()-1:
				length += route[i].distance_to(route[i+1])
			check(length < 600, "direct staircase path (%.0f pixels)" % length)
		var step := 0
		var ticks := 0
		while step < route.size() and ticks < 2500:
			var target := map.pixel_to_world(route[step])
			var to := Vector2(target.x-walker.global_position.x, target.z-walker.global_position.z)
			if to.length() < 0.18:
				step += 1
				continue
			release()
			if absf(to.x) > 0.06:
				Input.action_press(&"move_right" if to.x > 0 else &"move_left")
			if absf(to.y) > 0.06:
				Input.action_press(&"move_down" if to.y > 0 else &"move_up")
			await frames(1)
			ticks += 1
		release()
		await frames(10)
		check(walker.global_position.distance_to(door.front_point()) < 1.0,
			"walked to %s (%d frames, at %s)" % [door_name,ticks,map.world_to_pixel(walker.global_position)])
		if failures > 0:
			break
	check(int(SaveGame.data.area) == 3, "exploration remembers area 3")
	SaveGame.load_game()
	check(Levels.current_map() == Levels.MAPS[3], "reloaded save resumes workshops")
	map.swap_solo_character()
	await frames(5)
	check(PlayerSpawner.solo_slot == 1 and get_tree().get_nodes_in_group(&"walkers").size() == 1, "Tab swap supported")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ",failures)
	get_tree().quit(failures)

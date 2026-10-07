extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_travel.tscn
## Viagem de avião: o avião da Área 1 leva à cena do voo; escolher o Vulcão abre a Área 2 com a dupla na frente
## do avião e a área no save; as entradas da Área 2 ficam na estrada; o avião de lá leva de volta ao Circo.

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _ready() -> void:
	get_tree().create_timer(120.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_move_to_root.call_deferred()


func _move_to_root() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func _run() -> void:
	SaveGame.path = "user://test_save_travel.json"
	SaveGame.reset()
	PlayerSpawner.solo_slot = -1
	get_tree().change_scene_to_file(Levels.current_map())
	await frames(20)
	var map: PaintedWorld = get_tree().current_scene
	check(map.scene_file_path == Levels.MAP, "new save starts in area 1")
	var plane: WorldDoor = map.get_node("DoorPlane")
	check(plane.is_open() and map.is_walkable(plane.front_point()), "area 1 plane open, in front of the road")
	plane.try_enter()
	await frames(10)
	var travel := get_tree().current_scene
	check(travel.scene_file_path == Levels.TRAVEL, "plane opens the flight")
	await frames(60)
	check(travel.find_children("Area*", "Button", true, false).is_empty(), "no menu while flying")
	travel._end_flight()
	await frames(2)
	var buttons := travel.find_children("Area*", "Button", true, false)
	check(buttons.size() == 2, "menu shows the two areas")
	var focused := get_viewport().gui_get_focus_owner()
	check(focused != null and focused.name == "Area2", "focus starts on the other area")
	(focused as Button).pressed.emit()
	await frames(20)
	var volcano: PaintedWorld = get_tree().current_scene
	check(volcano.scene_file_path == Levels.MAPS[2], "volcano map loaded")
	check(int(SaveGame.data.area) == 2 and Levels.current_map() == Levels.MAPS[2], "save remembers area 2")
	var back: WorldDoor = volcano.get_node("DoorPlane")
	for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
		check(walker.global_position.distance_to(back.front_point()) < 3.0, "%s arrives at the plane" % walker.name)
		check(volcano.is_walkable(walker.global_position), "%s on the road" % walker.name)
	for door: WorldDoor in get_tree().get_nodes_in_group(&"world_doors"):
		check(volcano.is_walkable(door.front_point()), "%s front on the road" % door.name)
	check((volcano.get_node("DoorAnvil") as WorldDoor).status_text.is_empty() and not (volcano.get_node("DoorAnvil") as WorldDoor).is_open(), "boss without fight: coming soon")
	check((volcano.get_node("DoorMagmaKing") as WorldDoor).is_open(), "Magma King door opens his fight")
	# Curva da frente da mina: as pedras pintadas na frente cortavam a estrada e o boneco travava (07/10/2026).
	var bend := [Vector2(1100, 1450), Vector2(1110, 1540), Vector2(1170, 1560), Vector2(1300, 1530)]
	var cut := 0
	for i in bend.size() - 1:
		for k in 21:
			if not volcano.is_walkable(volcano.pixel_to_world(bend[i].lerp(bend[i + 1], k / 20.0))):
				cut += 1
	check(cut == 0, "volcano: the road around the mine bend is continuous (%d gaps)" % cut)
	check((volcano.get_node("DoorHeart") as WorldDoor).missing().size() == 3, "volcano heart locked until 3 wins")
	back.try_enter()
	await frames(10)
	travel = get_tree().current_scene
	travel._end_flight()
	await frames(2)
	travel.fly_to(1)
	await frames(20)
	check(get_tree().current_scene.scene_file_path == Levels.MAP and int(SaveGame.data.area) == 1, "plane goes back to area 1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("travel test: %d failures" % failures)
	get_tree().quit(failures)

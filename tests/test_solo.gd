extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_solo.tscn
## Jogar sozinho (06/10/2026): um personagem só no mapa e nas lutas; Tab no mapa troca o palhaço pela acrobata
## no mesmo lugar, e a escolha fica no save. Os dois saves de cada jeito de jogar (continuar ou do zero).

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _ready() -> void:
	get_tree().create_timer(90.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_move_to_root.call_deferred()


func _move_to_root() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func _run() -> void:
	await _check_slots()
	SaveGame.path = "user://test_save_solo.json"
	SaveGame.reset()
	PlayerSpawner.solo_slot = 0
	get_tree().change_scene_to_file(Levels.MAP)
	await frames(20)
	var map := get_tree().current_scene
	var walkers := get_tree().get_nodes_in_group(&"walkers")
	check(walkers.size() == 1 and walkers[0].name == "Player_1", "alone on the map as the clown")
	check(Shop.local_keys() == ["clown"], "only the clown is mine")
	var at: Vector3 = walkers[0].global_position
	map.swap_solo_character()
	await frames(5)
	walkers = get_tree().get_nodes_in_group(&"walkers")
	check(walkers.size() == 1 and walkers[0].name == "Player_2", "Tab turns into the acrobat")
	check(walkers.size() == 1 and walkers[0].global_position.distance_to(at) < 0.5, "same place after the swap")
	check(int(SaveGame.data.solo_character) == 1, "choice saved")
	(map.get_node("DoorTamer") as WorldDoor).try_enter()
	await frames(30)
	var fight := get_tree().current_scene
	check(fight.scene_file_path == "res://bosses/tamer/tamer_fight.tscn", "entered the tamer fight")
	var players := get_tree().get_nodes_in_group(&"players")
	check(players.size() == 1 and players[0].name == "Player_2", "only the acrobat fights")
	PlayerSpawner.solo_slot = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save_solo.json"))
	print("FAILURES: ", failures)
	get_tree().quit(failures)


## Dois saves por jeito de jogar: cada um continua ou começa do zero, sem mexer no outro.
func _check_slots() -> void:
	SaveGame.slot_folder = "user://test_slots_"
	for mode in SaveGame.SLOT_FILES:
		for slot in SaveGame.SLOT_COUNT:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.slot_path(mode, slot)))
	check(not SaveGame.slot_info("solo", 0).exists, "empty slot")
	SaveGame.use_slot("solo", 0, true)
	SaveGame.record_level("train")
	check(SaveGame.slot_info("solo", 0) == {"exists": true, "done": 1}, "slot 1 keeps the progress")
	SaveGame.use_slot("solo", 1, true)
	check(not SaveGame.is_defeated("train") and SaveGame.slot_info("solo", 0).done == 1, "slot 2 is a separate game")
	check(not SaveGame.slot_info("coop", 0).exists, "co-op saves untouched")
	SaveGame.use_slot("solo", 0)
	check(SaveGame.is_defeated("train"), "continue loads slot 1")
	SaveGame.use_slot("solo", 0, true)
	check(not SaveGame.is_defeated("train") and SaveGame.slot_info("solo", 0).done == 0, "from zero wipes slot 1")
	var menu: Node = load("res://core/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await frames(2)
	menu._show_slot_panel("solo")
	await frames(2)
	var rows: Array = menu._slot_panel.get_children().filter(func(node: Node) -> bool: return node is HBoxContainer)
	check(rows.size() == 2, "menu shows two saves")
	menu.queue_free()
	for mode in SaveGame.SLOT_FILES:
		for slot in SaveGame.SLOT_COUNT:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.slot_path(mode, slot)))
	SaveGame.slot_folder = "user://"

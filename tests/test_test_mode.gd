extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_test_mode.tscn
## Modo de teste ("Testar sozinho"): save à parte com ingressos de sobra, o Mágico aberto sem vencer
## ninguém e muita vida nas lutas; "Jogar sozinho" volta ao save normal, sem nada disso.

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
	# Liga o modo de teste num arquivo só deste teste (não mexe no save de teste do usuário).
	SaveGame.path = "user://test_save_mode.json"
	SaveGame.reset()
	SaveGame.test_mode = true  # o mesmo que SaveGame.use_test(), sem mexer no save de teste do usuário
	for key in SaveGame.PLAYER_KEYS:
		SaveGame.data.players[key].tickets = SaveGame.TEST_TICKETS
	get_tree().change_scene_to_file(Levels.MAP)
	await frames(20)
	var map := get_tree().current_scene
	var magician: WorldDoor = map.get_node("DoorMagician")
	check(magician.is_open() and magician.missing().is_empty(), "magician open in test mode")
	check(int(SaveGame.data.players.clown.tickets) >= SaveGame.TEST_TICKETS, "lots of tickets in test mode")
	magician.try_enter()
	await frames(30)
	var fight := get_tree().current_scene
	check(fight.scene_file_path == "res://bosses/magician/magician_fight.tscn", "entered the magician fight")
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		check(player.player_health.health.maximum == PlayerLoadout.TEST_HEALTH
			and player.player_health.health.current == PlayerLoadout.TEST_HEALTH, "%s has test health" % player.name)
		player.applause.spend(5)
		await frames(2)
		check(player.applause.full_stars() == 5, "%s special stays full" % player.name)
	# "Jogar sozinho": de volta ao normal.
	SaveGame.test_mode = false
	SaveGame.reset()
	var fresh: WorldDoor = load(Levels.MAP).instantiate().get_node("DoorMagician")
	check(not fresh.missing().is_empty(), "magician closed again outside test mode")
	fresh.get_parent().free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save_mode.json"))
	print("FAILURES: ", failures)
	get_tree().quit(failures)

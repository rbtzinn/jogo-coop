extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_map.tscn
## Mapa do parque: andar sem atirar, entrar na tenda do Domador, vencer, voltar ao mapa com a
## nota na tenda; tendas "Em breve" e fechadas não abrem.

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _ready() -> void:
	# Trava de segurança: se algo travar (ex.: erro de script), sai com falha.
	get_tree().create_timer(150.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	# Precisa sobreviver às trocas de cena: vai para a raiz.
	_move_to_root.call_deferred()


func _move_to_root() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func press(action: StringName) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)


func _run() -> void:
	SaveGame.path = "user://test_save_map.json"
	SaveGame.reset()
	get_tree().change_scene_to_file(Levels.MAP)
	await frames(20)
	var map := get_tree().current_scene
	check(map.scene_file_path == Levels.MAP, "map loaded")
	var clown: WorldWalker = map.get_node("PlayerSpawner/Player_1")
	var acro: WorldWalker = map.get_node("PlayerSpawner/Player_2")
	check(clown != null and acro != null, "both walkers in the world")
	await press(&"shoot")
	await frames(10)
	var shots := get_tree().current_scene.get_children().filter(func(n: Node) -> bool: return n is Projectile)
	check(shots.is_empty(), "no shooting on the map")

	# Tendas fechadas.
	var magician: WorldDoor = map.get_node("DoorMagician")
	for open_door in ["DoorJugglers", "DoorTrain", "DoorShop", "DoorDressing"]:
		check((map.get_node(open_door) as WorldDoor).is_open(), "%s open" % open_door)
	check(not magician.is_open() and magician.missing().size() == 3, "magician locked until 3 wins")
	magician.try_enter()
	await frames(5)
	check(get_tree().current_scene == map, "locked tent does not change scene")

	# Camarim pela porta: Atirar abre; Voltar e Esc fecham e ele não reabre sozinho (bug do usuário em 05/10/2026:
	# a porta relia o aperto que abriu o Camarim, guardado enquanto o jogo ficava pausado).
	var dressing: WorldDoor = map.get_node("DoorDressing")
	var spot := clown.global_position
	clown.global_position = dressing.front_point() + Vector3(0, 0.4, 0)
	await frames(5)
	await press(&"shoot")
	await frames(5)
	check(PauseMenu.is_open() and PauseMenu._dressing_room.visible, "dressing room opens from its door")
	PauseMenu._dressing_room.close()
	await frames(10)
	check(not PauseMenu.is_open(), "Voltar closes the dressing room for good")
	await press(&"shoot")
	await frames(5)
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await frames(10)
	check(not PauseMenu.is_open(), "Esc closes the dressing room for good")
	clown.global_position = spot
	await frames(5)

	# Andar até o Domador (para a direita e depois para cima, até a frente da tenda) e entrar.
	var door: WorldDoor = map.get_node("DoorTamer")
	var start := clown.global_position
	Input.action_press(&"move_right")
	await frames(40)
	Input.action_release(&"move_right")
	# Em 40 quadros, acelerando até SPEED (ACCEL m/s²): SPEED x t - SPEED² / (2 ACCEL). Exige 80% disso
	# (sobra para a rampa, o atrito e o desvio da trilha), para valer qualquer velocidade escolhida.
	var expected := WorldWalker.SPEED * 40.0 / 60.0 - WorldWalker.SPEED * WorldWalker.SPEED / (2.0 * WorldWalker.ACCEL)
	check(clown.global_position.x > start.x + expected * 0.8, "walked right in the world (%.2f of %.2f m)" % [clown.global_position.x - start.x, expected])
	check(acro.global_position.distance_to(clown.global_position) < 3.0, "partner follows when playing alone")
	# Tecla física de cima (W) com "Cima também pula" ligado (o padrão): no mapa ela anda para a frente.
	var up_jumps_before := Settings.up_jumps
	Settings.up_jumps = true
	start = clown.global_position
	var w_key := InputEventKey.new()
	w_key.physical_keycode = KEY_W
	w_key.pressed = true
	Input.parse_input_event(w_key)
	await frames(40)
	w_key = w_key.duplicate()
	w_key.pressed = false
	Input.parse_input_event(w_key)
	await frames(20)
	Settings.up_jumps = up_jumps_before
	check(clown.global_position.z < start.z - expected * 0.8, "W walks forward even with up-jumps on (%.2f m)" % (start.z - clown.global_position.z))
	var walked := 0
	while not door.overlaps_body(clown) and walked < 400:
		var to := door.front_point() - clown.global_position
		for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
			Input.action_release(action)
		if absf(to.x) > 0.3:
			Input.action_press(&"move_right" if to.x > 0.0 else &"move_left")
		if absf(to.z) > 0.3:
			Input.action_press(&"move_down" if to.z > 0.0 else &"move_up")
		await frames(1)
		walked += 1
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)
	check(door.overlaps_body(clown), "walked to the tamer tent")
	await frames(5)
	await press(&"shoot")
	await frames(20)
	var fight := get_tree().current_scene
	check(fight != null and fight.scene_file_path == "res://bosses/tamer/tamer_fight.tscn", "entered the tamer fight")
	var boss = fight.get_node("TamerBoss")
	boss._wait = 100000.0
	await frames(30)
	boss.apply_damage(boss.health.current)
	await frames(200)
	var screen: Node
	for child in fight.get_node("Fight").get_children():
		if child.get_script() == Fight.END_SCREEN:
			screen = child
	check(screen != null, "end screen")
	screen.back_to_map()
	await frames(20)
	map = get_tree().current_scene
	check(map.scene_file_path == Levels.MAP, "back on the map")
	var back: WorldWalker = map.get_node("PlayerSpawner/Player_1")
	check(back.global_position.distance_to(map.get_node("DoorTamer").global_position) < 6.0, "back in front of the tamer tent")
	check(SaveGame.is_defeated("tamer"), "tamer defeated in save")
	check(int(SaveGame.data.players.clown.tickets) >= 3, "tickets earned")
	check(map.get_node("DoorMagician").missing().size() == 2, "one lock less on the magician")
	var file := FileAccess.open(SaveGame.path, FileAccess.READ)
	check(file != null and file.get_as_text().contains("tamer"), "save file written")
	file = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))

	print("FAILURES: ", failures)
	get_tree().quit(failures)

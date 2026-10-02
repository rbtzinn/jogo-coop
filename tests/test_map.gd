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
	var clown: Player = map.get_node("PlayerSpawner/Player_1")
	check(not clown.armed, "players are unarmed on the map")
	await press(&"shoot")
	await frames(10)
	var shots := get_tree().current_scene.get_children().filter(func(n: Node) -> bool: return n is Projectile)
	check(shots.is_empty(), "no shooting on the map")

	# Tendas fechadas.
	var jugglers: MapDoor = map.get_node("DoorJugglers")
	var magician: MapDoor = map.get_node("DoorMagician")
	check(not jugglers.is_open(), "coming soon tent closed")
	check(not magician.is_open() and magician.missing().size() == 3, "magician locked until 3 wins")
	jugglers.try_enter()
	await frames(5)
	check(get_tree().current_scene == map, "closed tent does not change scene")

	# Andar até o Domador e entrar.
	var door: MapDoor = map.get_node("DoorTamer")
	Input.action_press(&"move_right")
	var walked := 0
	while not door.overlaps_body(clown) and walked < 300:
		await frames(1)
		walked += 1
	Input.action_release(&"move_right")
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
	check(SaveGame.is_defeated("tamer"), "tamer defeated in save")
	check(int(SaveGame.data.players.clown.tickets) >= 3, "tickets earned")
	check(map.get_node("DoorMagician").missing().size() == 2, "one lock less on the magician")
	var file := FileAccess.open(SaveGame.path, FileAccess.READ)
	check(file != null and file.get_as_text().contains("tamer"), "save file written")
	file = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))

	print("FAILURES: ", failures)
	get_tree().quit(failures)

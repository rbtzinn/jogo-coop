extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_train.tscn
## Corrida no Trem do Circo: montagem da fase, câmera, cair no vão, inimigos, ponte baixa
## (em pé machuca, abaixado passa), ingresso escondido e chegada na locomotiva.

const TrainLevel := preload("res://levels/train/train_level.gd")

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _ready() -> void:
	get_tree().create_timer(150.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


func _run() -> void:
	SaveGame.path = "user://test_save_train.json"
	SaveGame.reset()
	var scene: Node2D = load("res://levels/train/train_level.tscn").instantiate()
	add_child(scene)
	await frames(30)
	var level: RunLevel = scene.get_node("RunLevel")
	var clown: Player = scene.get_node("PlayerSpawner/Player_1")
	var acrobat: Player = scene.get_node("PlayerSpawner/Player_2")
	check(clown.is_on_floor() and absf(clown.global_position.y - TrainLevel.ROOF_Y) < 2.0, "players stand on the first wagon")
	check(get_tree().get_nodes_in_group(&"enemies").size() == TrainLevel.ENEMIES.size(), "enemies built")
	check(get_tree().get_nodes_in_group(&"hidden_tickets").size() == 3, "three hidden tickets")
	check(level.started and level.clock > 0.0, "level clock running")

	# Tira os inimigos do caminho (o resto do teste não depende deles).
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	var first: Enemy = enemies[0]
	level.report_enemy_hit(first, 100)
	check(first.dead, "enemy defeated")
	for enemy: Enemy in enemies:
		level.report_enemy_hit(enemy, 100)
	await frames(30)

	# Câmera: segue a dupla e não deixa sair da tela.
	var camera: GroupCamera = scene.get_node("Camera")
	clown.global_position.x = 1500.0
	acrobat.global_position.x = 1400.0
	await frames(90)
	check(absf(camera.global_position.x - 1450.0) < 40.0, "camera follows the pair (%.0f)" % camera.global_position.x)
	clown.global_position.x = 3500.0
	await frames(2)
	check(clown.global_position.x <= camera.view_rect().end.x, "runner kept inside the screen")

	# Cair no vão entre o 1º e o 2º vagão: perde 1 vida e volta no 1º.
	clown.global_position = Vector2(980.0, 760.0)
	acrobat.global_position = Vector2(1000.0, 650.0)
	await frames(60)
	check(clown.player_health.health.current == 2, "falling costs one heart (%d)" % clown.player_health.health.current)
	check(clown.global_position.y <= TrainLevel.ROOF_Y + 2.0 and camera.view_rect().has_point(clown.global_position), "respawned on a wagon on screen (%s)" % clown.global_position)
	# Com a câmera lá na frente, volta no primeiro vagão que está na tela.
	camera.global_position.x = 3000.0
	acrobat.global_position = Vector2(3300.0, 650.0)
	clown.global_position = Vector2(2600.0, 900.0)
	await frames(10)
	check(absf(clown.global_position.x - 2790.0) < 5.0, "respawn stays on screen (%.0f)" % clown.global_position.x)
	clown.player_health.health.set_current(2)

	# Ponte baixa parada em x = 3000 (o relógio é segurado pelo teste).
	var bridge_clock := TrainLevel.FIRST_BRIDGE + (TrainLevel.LEVEL_WIDTH + 600.0 - 3000.0) / TrainLevel.BRIDGE_SPEED
	camera.global_position.x = 2925.0
	clown.global_position = Vector2(3000.0, TrainLevel.ROOF_Y)
	acrobat.global_position = Vector2(2850.0, TrainLevel.ROOF_Y)
	clown.player_health._invincible_timer = 0.0
	Input.action_press(&"move_down")
	for i in 40:
		level.clock = bridge_clock
		await get_tree().physics_frame
	check(clown.crouching and clown.player_health.health.current == 2 and absf(clown.global_position.x - 3000.0) < 30.0, "crouching passes under the low bridge")
	Input.action_release(&"move_down")
	for i in 20:
		level.clock = bridge_clock
		await get_tree().physics_frame
	check(clown.player_health.health.current == 1, "standing hits the low bridge")
	clown.player_health.health.set_current(3)
	level.clock = 0.5

	# Ingresso escondido.
	clown.global_position = Vector2(TrainLevel.TICKETS[0][0], TrainLevel.TICKETS[0][1] + 40.0)
	await frames(5)
	check(SaveGame.has_ticket("train:1"), "ticket collected")
	check(int(SaveGame.data.players.acrobat.tickets) == 1, "both players got the ticket")

	# Chegada na locomotiva (a câmera vai junto, senão ela segura os jogadores).
	camera.global_position.x = TrainLevel.LEVEL_WIDTH - 960.0
	# Os dois na locomotiva (o último vagão), perto do fim da linha.
	var engine: Array = TrainLevel.WAGONS[-1]
	acrobat.global_position = Vector2(engine[0] + 340.0, TrainLevel.ROOF_Y)
	clown.global_position = Vector2(engine[0] + 500.0, TrainLevel.ROOF_Y)
	await frames(200)
	check(level._ended, "level complete at the locomotive")
	check(SaveGame.is_defeated("train"), "train saved as done")
	var screen: Node
	for child in level.get_children():
		if child.get_script() == RunLevel.END_SCREEN:
			screen = child
	check(screen != null and screen.result.get("tickets_found", 0) == 1, "end screen shows tickets found")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))

	print("FAILURES: ", failures)
	get_tree().quit(failures)

extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_back_wall.tscn
## Parede invisível atrás dos chefões de canto (pedido de 14/10/2026): andando para a parede, o jogador para
## encostado no chefão e não passa para trás dele.

const CASES := [
	["res://bosses/jugglers/jugglers_fight.tscn", -1.0, "Malabaristas, canto esquerdo"],
	["res://bosses/jugglers/jugglers_fight.tscn", 1.0, "Malabaristas, canto direito"],
	["res://bosses/magma_king/magma_king_fight.tscn", 1.0, "Rei Magma, canto direito"],
	["res://bosses/volcano_heart/volcano_heart_fight.tscn", 1.0, "Coração do Vulcão, canto direito"],
]

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func _ready() -> void:
	SaveGame.path = "user://test_save_back_wall.json"
	SaveGame.reset()
	for case: Array in CASES:
		await _walk_into_corner(case[0], case[1], case[2])
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame
	check((scene.get_node("Fight") as Fight).boss.get_node_or_null("BackWall") == null, "Domador (anda pela arena) não ganha parede")
	scene.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)


func _walk_into_corner(path: String, side: float, label: String) -> void:
	var scene: Node = load(path).instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000, 100000)
	await get_tree().physics_frame
	var players: Array[Player] = []
	for node in get_tree().get_nodes_in_group(&"players"):
		players.append(node as Player)
	var walker := players[0]
	for player in players:
		player.input.local_control = player == walker
		player.player_health._invincible_timer = 10000.0
	walker.global_position = Vector2(960.0, 990.0)
	for other in players:
		if other != walker:
			other.global_position = Vector2(960.0 - side * 300.0, 990.0)
	var action := &"move_right" if side > 0.0 else &"move_left"
	Input.action_press(action)
	for i in 240:
		await get_tree().physics_frame
		walker.player_health._invincible_timer = 10000.0
	Input.action_release(action)
	var wall := boss.get_node("BackWall") as BossBackWall
	var edge := wall.right_edge if side > 0.0 else wall.left_edge
	check(not is_inf(edge), "%s: parede atrás do chefão" % label)
	var behind := walker.global_position.x > edge if side > 0.0 else walker.global_position.x < edge
	check(not behind, "%s: jogador para no chefão (x %.0f, parede em %.0f)" % [label, walker.global_position.x, edge])
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

extends Node
## Teste online do Especial com dois processos sem janela no mesmo PC (host e cliente):
##   Godot --headless --path . res://tests/test_online.tscn -- host
##   Godot --headless --path . res://tests/test_online.tscn -- client
## (rodar os dois juntos; ver tests/run_online.sh). Cada processo sai com o número de falhas.
## O host é o palhaço, o cliente é a acrobata (como no jogo).

const PORT := 24690
const FIGHT := "res://bosses/tamer/tamer_fight.tscn"

var failures := 0
var role := ""


func _ready() -> void:
	role = "host" if "host" in OS.get_cmdline_user_args() else "client"
	# Este nó precisa sobreviver à troca de cena: vai para a raiz.
	_move_to_root.call_deferred()


func _move_to_root() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func check(ok: bool, label: String) -> void:
	print("[%s] %s %s" % [role, "OK  " if ok else "FAIL", label])
	if not ok:
		failures += 1


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func press_special() -> void:
	Input.action_press("special")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("special")


func _run() -> void:
	get_tree().create_timer(60.0).timeout.connect(func() -> void:
		print("[%s] FAIL timeout" % role)
		get_tree().quit(99))
	# Nunca mexe no save de verdade.
	SaveGame.path = "user://test_save_%s.json" % role
	SaveGame.reset()
	if role == "host":
		check(Network.host(PORT) == OK, "host opened")
		get_tree().change_scene_to_file(FIGHT)
	else:
		await wait(1.0)
		check(Network.join("127.0.0.1:%d" % PORT) == OK, "join started")
		await Network.joined
		get_tree().change_scene_to_file(FIGHT)
	while Network.ready_peers.is_empty():
		await wait(0.1)
	await wait(1.0)
	var scene := get_tree().current_scene
	var boss = scene.get_node("TamerBoss")
	boss._wait = 100000.0
	var clown: Player = scene.get_node("PlayerSpawner/Player_1")
	var acro: Player
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player != clown:
			acro = player
	check(acro != null, "both players exist")
	var me := clown if role == "host" else acro
	var partner := acro if role == "host" else clown
	var duo := DuoActs.find(get_tree())
	me.global_position = Vector2(1000 if role == "host" else 1150, 1000)
	me.facing = 1
	await wait(0.5)

	# 1) Host solta o Tiro EX: o cliente vê a rolha (só visual) e a vida do chefão cai nos dois.
	var health_before: int = boss.health.current
	if role == "host":
		me.applause.stars = 1.0
		await press_special()
	await wait(0.6)
	if role == "client":
		check(_count_projectiles(get_tree().current_scene, false) == 1, "client sees host cork (visual only)")
	await wait(0.9)
	check(boss.health.current < health_before, "EX from host damaged boss (%d -> %d)" % [health_before, boss.health.current])

	# 2) Cliente solta o Tiro EX: o dano chega no host.
	health_before = boss.health.current
	if role == "client":
		me.applause.stars = 1.0
		await press_special()
	await wait(1.5)
	check(boss.health.current < health_before, "EX from client damaged boss (%d -> %d)" % [health_before, boss.health.current])

	# 3) Grande Número em Dupla: o host solta; o cliente solta logo que vê o do host.
	health_before = boss.health.current
	me.applause.stars = 5.0
	if role == "host":
		await press_special()
	else:
		while not partner.special.is_performing():
			await get_tree().physics_frame
		await press_special()
		check(me.special.is_performing(), "client grand performing")
	await wait(2.5)
	check(duo._last_duo > 0.0, "duo declared on this PC")
	print("[%s] boss after duo: %d -> %d" % [role, health_before, boss.health.current])
	check(boss.health.current < health_before - 250, "duo dealt big damage")

	# 4) Número Perfeito: o host estoura um objeto; o cliente dá parry nele logo depois.
	me.applause.stars = 0.0
	await wait(0.5)
	if role == "host":
		duo.report_parry("teste:perfeito", me, Vector2(900, 700))
		me.sync.send_parry("teste:perfeito")
	else:
		while not duo._parries.has("teste:perfeito"):
			await get_tree().physics_frame
		duo.report_parry("teste:perfeito", me, Vector2(900, 700))
		me.sync.send_parry("teste:perfeito")
	await wait(1.0)
	check(is_equal_approx(me.applause.stars, 1.0), "perfect bonus star (%.2f)" % me.applause.stars)

	# 5) Vitória: o host calcula a nota e manda; o cliente mostra a mesma.
	if role == "host":
		boss.apply_damage(boss.health.current)
	await wait(3.5)
	var fight: Fight = scene.get_node("Fight")
	var screen: Node
	for child in fight.get_children():
		if child.get_script() == Fight.END_SCREEN:
			screen = child
	check(screen != null and screen.victory, "victory screen")
	if screen != null:
		print("[%s] result: %s" % [role, screen.result])
		check(not String(screen.result.get("grade", "")).is_empty(), "grade shown")
	check(SaveGame.is_defeated("tamer") == (role == "host"), "only the host saves")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	await wait(1.0)
	print("[%s] FAILURES: %d" % [role, failures])
	get_tree().quit(failures)


func _count_projectiles(scene: Node, damaging: bool) -> int:
	var count := 0
	for node in scene.get_children():
		if node is PiercingProjectile and node.deals_damage == damaging:
			count += 1
	return count

extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_special.tscn
## Teste headless do Especial: Tiro EX, Grande Número dos dois, dupla e Número Perfeito.

var failures := 0


func _ready() -> void:
	# Trava de segurança: se algo travar (ex.: erro de script), sai com falha.
	get_tree().create_timer(150.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func press_special() -> void:
	Input.action_press("special")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("special")


func _run() -> void:
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	await frames(10)
	# Tiros, tortas e efeitos nascem na cena atual (este nó).
	var world: Node = get_tree().current_scene
	var boss = scene.get_node("TamerBoss")
	boss._wait = 100000.0
	var clown: Player = scene.get_node("PlayerSpawner/Player_1")
	var acro: Player = scene.get_node("PlayerSpawner/Player_2")
	check(clown.special._grand != null and acro.special._grand != null, "grand numbers created")
	await frames(40)

	# --- Tiro EX ---
	clown.applause.stars = 1.5
	clown.global_position = Vector2(1100, 1000)
	clown.facing = 1
	await frames(5)
	await press_special()
	var corks := world.get_children().filter(func(n: Node) -> bool: return n is PiercingProjectile)
	check(corks.size() == 1, "EX spawned one cork (%d)" % corks.size())
	check(is_equal_approx(clown.applause.stars, 0.5), "EX spent 1 star (%.2f)" % clown.applause.stars)
	check(clown.special.is_recoiling(), "EX recoil active")
	var health_before: int = boss.health.current
	await frames(60)
	print("boss health after EX: ", health_before, " -> ", boss.health.current)
	check(boss.health.current < health_before, "EX damaged boss")
	check(clown.applause.stars < 0.6, "EX damage gave no stars (%.2f)" % clown.applause.stars)

	# --- Sem estrela: nada ---
	clown.applause.stars = 0.2
	await press_special()
	check(is_equal_approx(clown.applause.stars, 0.2) and not clown.special.is_busy(), "no star, nothing happens")

	# --- Torta na Cara ---
	clown.applause.stars = 5.0
	health_before = boss.health.current
	await press_special()
	check(clown.special.is_performing(), "clown grand performing")
	check(clown.special.is_invincible(), "clown invincible")
	check(clown.applause.stars < 0.01, "grand spent 5 stars")
	await frames(30)
	var pies := world.get_children().filter(func(n: Node) -> bool: return n.scene_file_path.ends_with("pie.tscn"))
	check(pies.size() == 1, "pie thrown (%d)" % pies.size())
	await frames(90)
	print("boss health after pie: ", health_before, " -> ", boss.health.current)
	check(boss.health.current < health_before - 50, "pie dealt big damage")
	check(not clown.special.is_performing(), "clown grand ended")

	# --- Salto Mortal (troca o controle para a acrobata) ---
	clown.input.local_control = false
	acro.input.local_control = true
	acro.global_position = Vector2(900, 1000)
	acro.facing = 1
	await frames(5)
	acro.applause.stars = 5.0
	health_before = boss.health.current
	var start_x := acro.global_position.x
	await press_special()
	check(acro.special.is_performing(), "acrobat grand performing")
	var min_y := 99999.0
	for i in 60:
		await get_tree().physics_frame
		min_y = minf(min_y, acro.global_position.y)
	print("acrobat moved x ", start_x, " -> ", acro.global_position.x, " min y ", min_y)
	check(acro.global_position.x > start_x + 400.0, "acrobat leapt forward")
	check(min_y < 750.0, "acrobat went high")
	print("boss health after somersault: ", health_before, " -> ", boss.health.current)
	check(boss.health.current < health_before, "somersault damaged boss")
	await frames(30)

	# --- Grande Número em Dupla ---
	var duo: DuoActs = DuoActs.find(get_tree())
	check(duo != null, "DuoActs exists")
	acro.input.local_control = false
	clown.input.local_control = true
	clown.applause.stars = 5.0
	acro.applause.stars = 5.0
	# As janelas usam o relógio real; aqui o jogo roda mais rápido que ele.
	duo._grand_numbers.clear()
	duo._last_duo = -INF
	await press_special()
	check(duo._last_duo < 0.0, "one grand number alone is not a duo")
	await frames(20)
	clown.input.local_control = false
	acro.input.local_control = true
	health_before = boss.health.current
	await press_special()
	check(duo._last_duo > 0.0, "duo declared")
	var finales := world.get_children().filter(func(n: Node) -> bool: return n is DuoFinale)
	check(finales.size() == 1, "duo finale spawned (%d)" % finales.size())
	await frames(120)
	print("boss health after duo: ", health_before, " -> ", boss.health.current)

	# --- Número Perfeito ---
	clown.applause.stars = 0.0
	acro.applause.stars = 0.0
	duo.report_parry("teste:1", clown, Vector2(800, 700))
	await frames(6)
	duo.report_parry("teste:1", acro, Vector2(800, 700))
	check(is_equal_approx(clown.applause.stars, 1.0) and is_equal_approx(acro.applause.stars, 1.0), "perfect gave +1 each")
	duo.report_parry("teste:2", clown, Vector2(800, 700))
	OS.delay_msec(400)
	duo.report_parry("teste:2", acro, Vector2(800, 700))
	check(is_equal_approx(clown.applause.stars, 1.0), "late partner parry: no bonus")

	# --- Janela do parceiro no objeto rosa ---
	var hitbox := EnemyHitbox.new()
	hitbox.parryable = true
	scene.add_child(hitbox)
	check(hitbox.can_parry("Player_1"), "pink can be parried")
	hitbox.register_parry("Player_1")
	check(not hitbox.can_parry("Player_1"), "same player cannot parry again")
	check(hitbox.can_parry("Player_2"), "partner can parry right after")
	OS.delay_msec(400)
	check(not hitbox.can_parry("Player_2"), "partner window closes")

	print("FAILURES: ", failures)
	get_tree().quit(failures)

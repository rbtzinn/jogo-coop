extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_jugglers.tscn
## Mecânica dos Irmãos Malabaristas: cada um com sua vida, tontura no limite da fase, bola de
## cura depois de 3 s (um parry estoura), troca de fase só com os dois derrubados juntos e, no
## monociclo, o dano passa para quem ainda tem vida.

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func seconds(value: float) -> void:
	for i in int(value * 60.0):
		await get_tree().physics_frame


func _ready() -> void:
	get_tree().create_timer(150.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


func _run() -> void:
	SaveGame.path = "user://test_save_jugglers.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/jugglers/jugglers_fight.tscn").instantiate()
	add_child(scene)
	var boss: JugglersBoss = scene.get_node("JugglersBoss")
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	boss._wait = 100000.0
	await seconds(0.5)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0

	# Fase 1: o Tico não passa do limite e fica tonto.
	boss.apply_damage(1000, "", "Tico")
	check(boss.hp.Tico == 360 and boss.hp.Teco == 600, "Tico stops at the phase limit (%d)" % boss.hp.Tico)
	check(boss.tico.dizzy and not boss.teco.dizzy, "Tico dizzy")
	check(boss.health.current == 960 and boss.phase == 0, "still phase 1")
	await seconds(3.2)
	check(boss._heal != null and boss._heal.pink, "Teco throws a pink heal ball after 3 s")
	await seconds(1.3)
	check(boss.hp.Tico > 360 and not boss.tico.dizzy, "heal landed (%d)" % boss.hp.Tico)

	# A cura estourada com parry não cura.
	boss.apply_damage(1000, "", "Tico")
	await seconds(3.1)
	check(boss._heal != null, "second heal ball")
	if boss._heal != null:
		boss._heal.register_parry("Player_1")
	await seconds(1.3)
	check(boss.hp.Tico == 360 and boss.tico.dizzy, "parried heal does not heal")

	# Tonto fica parado (pedido do usuário em 04/10/2026): não troca de lugar nem arremessa; o outro joga.
	boss.dizzy_since.Tico = boss._clock + 1000.0  # sem bola de cura durante esta parte
	check(not boss._can_choose(&"Swap") and boss._can_choose(&"JugglePass"), "no Swap while a brother is dizzy")
	var tico_at := boss.tico.global_position
	var tico_left := boss.left() == boss.tico
	var dizzy_moves := [0]
	var watch := func() -> void:
		if boss.tico.pose in [&"throw", &"crouch", &"spin"] or not boss.tico._dizzy_art() \
				or boss.tico.global_position.distance_to(tico_at) > 0.5:
			dizzy_moves[0] += 1
			if dizzy_moves[0] <= 3:
				print("  dizzy Tico: pose %s, dizzy drawing %s, moved %.1f" % [boss.tico.pose, boss.tico._dizzy_art(), boss.tico.global_position.distance_to(tico_at)])
	var juggle_pass: BossAttack = boss.get_node("Attacks/JugglePass")
	boss.sync.start_attack(&"JugglePass", 11, boss._args_for(&"JugglePass"))
	var thrown := [0, 0]
	var counted := {}
	while juggle_pass.is_running():
		await get_tree().physics_frame
		watch.call()
		for i in juggle_pass._throws.size():
			var throw: Array = juggle_pass._throws[i]
			if is_instance_valid(throw[3]) and not counted.has(i):
				counted[i] = true
				thrown[0 if throw[1] == tico_left else 1] += 1
	check(thrown[0] == 0 and thrown[1] == 3, "dizzy Tico throws nothing, Teco throws his 3 (%s)" % [thrown])
	var swap: BossAttack = boss.get_node("Attacks/Swap")
	boss.sync.start_attack(&"Swap", 12, boss._args_for(&"Swap"))
	while swap.is_running():
		await get_tree().physics_frame
		watch.call()
	check(boss.tico.global_position.distance_to(tico_at) < 0.5 and boss.teco.global_position.x > 960.0, "a forced Swap gives up: nobody jumps")
	var throwers := []
	for seed_value in range(20, 28):
		boss.sync.start_attack(&"BounceBalls", seed_value, boss._args_for(&"BounceBalls"))
		await get_tree().physics_frame
		watch.call()
		throwers.append(String(boss.get_node("Attacks/BounceBalls")._thrower.name))
	check(not throwers.has("Tico"), "bouncing balls always thrown by Teco (%s)" % [throwers])
	check(dizzy_moves[0] == 0, "dizzy Tico never moved or left the dizzy drawing (%d frames)" % dizzy_moves[0])
	await seconds(4.0)

	# Os dois juntos: troca para o totem.
	boss.apply_damage(1000, "", "Teco")
	await seconds(0.2)
	check(boss.phase == 1, "both down: phase 2")
	await seconds(3.0)
	check(boss.mode == &"totem" and not boss.tico.dizzy, "totem mode, dizziness cleared")
	check(absf(boss.top().global_position.y - (boss.base().global_position.y - JugglersBoss.TOTEM_SHOULDER)) < 1.0, "one on the other's shoulders")

	# Totem desenhado (E7): a base desenha os dois (a folha do irmão que está embaixo), o de cima só tem as áreas.
	var base := boss.base()
	var top := boss.top()
	await seconds(0.1)
	check(base._totem_art() and top._totem_hidden() and base._art_holder.visible and not top._art_holder.visible,
			"totem: the base draws both, the top draws no body")
	var sheet: FrameAnimation = Juggler.TOTEM_TECO if base.teco else Juggler.TOTEM_TICO
	check(sheet.frames.has(base._art.texture), "totem: sheet of the brother at the bottom (%s)" % base.name)
	# Desde 05/10/2026 o totem é maior: o de cima pega quem está em cima da tábua pendurada (o topo dela a 240
	# px do chão), mas do chão ainda se pula por cima (a área que machuca fica abaixo do pulo, 270 px).
	var board: Node2D = scene.get_node("PlatformRight")
	var board_bottom := board.global_position.y + 12.0
	var tallest := 0.0
	for texture: Texture2D in sheet.frames:
		tallest = maxf(tallest, -(sheet.origin.y + texture.get_image().get_used_rect().position.y * sheet.frame_scale))
	var top_hit := top.hitbox.get_child(0) as CollisionShape2D
	var top_hurt := top.hurtbox.get_child(0) as CollisionShape2D
	var board_top := board.global_position.y - 12.0
	var hit_top := top_hit.global_position.y - (top_hit.shape as RectangleShape2D).size.y * 0.5
	check(base.global_position.y - tallest * Juggler.TOTEM_GROW < board_top, "totem drawing taller than the board (%.1f px)" % (tallest * Juggler.TOTEM_GROW))
	check(hit_top < board_top - 15.0, "totem hits whoever stands on the board (%.0f px above its top)" % (board_top - hit_top))
	check(base.global_position.y - hit_top < 270.0, "totem still jumpable from the floor (%.0f px)" % (base.global_position.y - hit_top))
	# Claves em Linha: a clave nasce na luva do desenho de soltura (8) que está na tela.
	var volley: BossAttack = boss.get_node("Attacks/ClubVolley")
	boss.sync.start_attack(&"ClubVolley", 21, boss._args_for(&"ClubVolley"))
	var club_gap := -1.0
	var club_frame := -1
	while volley.is_running() and club_gap < 0.0:
		await get_tree().physics_frame
		for child in volley.get_children():
			if child is JugglerProp:
				club_gap = (child as Node2D).global_position.distance_to(top.hand_position())
				club_frame = base.totem_frame()
				break
	check(club_gap >= 0.0 and club_gap <= 15.0 and club_frame == 7, "club born in the drawn hand (%.1f px, drawing %d)" % [club_gap, club_frame + 1])
	while volley.is_running():
		await get_tree().physics_frame

	# Fase 2 para a 3 (monociclo).
	boss.apply_damage(1000, "", "Tico")
	boss.apply_damage(1000, "", "Teco")
	await seconds(3.0)
	check(boss.phase == 2 and boss.mode == &"unicycle" and boss.unicycle.visible, "unicycle phase")
	# O de baixo, no selim, pega quem está em cima da tábua (05/10/2026); a roda ainda passa por baixo dela.
	var seat_board: Node2D = scene.get_node("PlatformRight")
	check(boss.base().global_position.y > seat_board.global_position.y - 12.0 - 125.0, "unicycle riders reach the board")
	check(boss.unicycle.global_position.y - 2.0 * Unicycle.WHEEL_RADIUS > seat_board.global_position.y + 12.0 - 6.0, "unicycle wheel passes under the board")

	# Fase 3: sem limite; quem chega a zero passa o dano para o outro.
	boss.apply_damage(1000, "", "Tico")
	check(boss.hp.Tico == 0 and not boss.is_defeated, "Tico at zero, fight goes on")
	boss.apply_damage(50, "", "Tico")
	check(boss.hp.Teco == boss.health.current and boss.hp.Teco < 187, "damage on Tico goes to Teco")
	boss.apply_damage(1000, "", "Teco")
	await seconds(0.5)
	check(boss.is_defeated, "both at zero: defeated")
	await seconds(3.0)
	check(SaveGame.is_defeated("jugglers"), "jugglers saved as defeated")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))

	print("FAILURES: ", failures)
	get_tree().quit(failures)

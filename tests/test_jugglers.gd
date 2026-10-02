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
	check(boss.hp.Tico == 450 and boss.hp.Teco == 750, "Tico stops at the phase limit (%d)" % boss.hp.Tico)
	check(boss.tico.dizzy and not boss.teco.dizzy, "Tico dizzy")
	check(boss.health.current == 1200 and boss.phase == 0, "still phase 1")
	await seconds(3.2)
	check(boss._heal != null and boss._heal.pink, "Teco throws a pink heal ball after 3 s")
	await seconds(1.3)
	check(boss.hp.Tico > 450 and not boss.tico.dizzy, "heal landed (%d)" % boss.hp.Tico)

	# A cura estourada com parry não cura.
	boss.apply_damage(1000, "", "Tico")
	await seconds(3.1)
	check(boss._heal != null, "second heal ball")
	if boss._heal != null:
		boss._heal.register_parry("Player_1")
	await seconds(1.3)
	check(boss.hp.Tico == 450 and boss.tico.dizzy, "parried heal does not heal")

	# Os dois juntos: troca para o totem.
	boss.apply_damage(1000, "", "Teco")
	await seconds(0.2)
	check(boss.phase == 1, "both down: phase 2")
	await seconds(3.0)
	check(boss.mode == &"totem" and not boss.tico.dizzy, "totem mode, dizziness cleared")
	check(absf(boss.top().global_position.y - (boss.base().global_position.y - JugglersBoss.SHOULDER)) < 1.0, "one on the other's shoulders")

	# Fase 2 para a 3 (monociclo).
	boss.apply_damage(1000, "", "Tico")
	boss.apply_damage(1000, "", "Teco")
	await seconds(3.0)
	check(boss.phase == 2 and boss.mode == &"unicycle" and boss.unicycle.visible, "unicycle phase")

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

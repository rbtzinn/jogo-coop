extends Node
## Ferramenta (não é teste): abre uma luta com janela, passa por todas as fases e ataques e
## salva uma foto de cada momento, para conferir o desenho sem jogar.
## Rodar (com janela, não headless):
##   Godot --path . res://tests/screenshots.tscn -- <cena da luta> <pasta de saída>

var _out := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("uso: -- <cena> <pasta>")
		get_tree().quit(1)
		return
	_out = args[1]
	DirAccess.make_dir_recursive_absolute(_out)
	_run(args[0])


func seconds(value: float) -> void:
	await get_tree().create_timer(value).timeout


func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(960, 540)
	image.save_png(_out.path_join(label + ".png"))
	print("foto: ", label)


func _run(path: String) -> void:
	SaveGame.path = "user://test_save_shots.json"
	SaveGame.reset()
	var scene: Node = load(path).instantiate()
	add_child(scene)
	var boss: BossBrain = (scene.get_node("Fight") as Fight).boss
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	boss._wait = 100000.0
	await seconds(1.0)
	await shot("00_inicio")
	for phase in boss.phase_shares.size():
		if phase > 0:
			var parts: Array = [""]
			if boss.has_method(&"sub_bars"):
				parts = boss.sub_bars().map(func(entry: Array) -> String: return entry[0])
			for part: String in parts:
				boss.apply_damage(boss.health.current - boss.phase_end_health() if part.is_empty() else boss.health.current, "", part)
			await seconds(0.8)
			await shot("%d0_troca_de_fase" % phase)
			await seconds(2.6)
		for attack_name: StringName in boss.phase_attacks[phase]:
			for player: Player in get_tree().get_nodes_in_group(&"players"):
				player.player_health._invincible_timer = 1000.0
			boss.sync.start_attack(attack_name, randi(), boss._args_for(attack_name))
			await seconds(0.9)
			await shot("%d_%s_a" % [phase, attack_name])
			await seconds(0.8)
			await shot("%d_%s_b" % [phase, attack_name])
			while boss._current != null and boss._current.is_running():
				await seconds(0.1)
	boss.apply_damage(100000, "", "")
	for part in ["Tico", "Teco"]:
		boss.apply_damage(100000, "", part)
	await seconds(1.5)
	await shot("99_vitoria")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()

extends Node
var scene: Node
var boss: MadameCarretelBoss
const OUT := "res://build/qa/carretel/fight/"

func _ready() -> void:
	_run.call_deferred()

func frames(n: int) -> void:
	for i in n: await get_tree().physics_frame

func photo(label: String) -> void:
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.visual.show()
		player.player_health._blink_timer = 1000
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+label+".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	SaveGame.path = "user://carretel_visual_check.json"
	SaveGame.reset()
	PlayerSpawner.solo_slot = -1
	scene = load("res://bosses/madame_carretel/madame_carretel_fight.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	boss = scene.get_node("MadameCarretelBoss")
	boss.pause_between_attacks = Vector2(99999,99999)
	boss._wait = 99999
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.input.local_control = false
		player.player_health._invincible_timer = 99999
	await frames(220)
	await photo("phase1")
	for attack in [&"Needles",&"Tape",&"Scissors"]:
		boss.sync.start_attack(attack,93,[Vector2(300,875),Vector2(490,875)])
		await frames(115 if attack==&"Needles" else 90)
		await photo(String(attack))
		boss._current.cancel()
		await frames(3)
	boss.health.damage(boss.health.current-boss.phase_end_health())
	await frames(220)
	boss.sync.start_attack(&"Curtains",93,[Vector2(600,875),Vector2(1100,875)])
	await frames(105)
	await photo("phase2_curtains")
	boss._current.cancel()
	boss.health.damage(boss.health.current-boss.phase_end_health())
	await frames(220)
	boss.sync.start_attack(&"Buttons",93,[Vector2(300,875),Vector2(490,875)])
	await frames(184)
	await photo("phase3_buttons")
	MobileControls.enable()
	await frames(3)
	await photo("mobile")
	boss._current.cancel()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()

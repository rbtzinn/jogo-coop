extends Node
## Fotos da luta do Maestro em momentos-chave de cada ataque (para conferir a arte feita em código).
## Uso: Godot --path . --fixed-fps 60 res://tools/maestro_fight_capture.tscn (precisa de janela; salva em build/qa).
const OUT := "res://build/qa/maestro/fight/"
## Ataque, fase e quantos segundos depois do começo tirar a foto.
const SHOTS := [
	[&"Staff", 0, 0.9], [&"Staff", 0, 2.6], [&"Baton", 0, 0.9], [&"Baton", 0, 1.35], [&"Metronome", 0, 0.9],
	[&"Metronome", 0, 2.9], [&"IntroOrgan", 1, 1.2], [&"Waves", 1, 2.4], [&"Eighths", 1, 1.15], [&"StaffWaves", 1, 3.0],
	[&"IntroFinale", 2, 0.8], [&"Pipes", 2, 0.9], [&"Pipes", 2, 1.6], [&"StaffEighths", 2, 2.6], [&"BatonWaves", 2, 7.9],
]
var scene: Node
var boss: RustMaestroBoss


func _ready() -> void:
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func photo(label: String) -> void:
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.visual.show()
		player.player_health._blink_timer = 1000
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + label + ".png")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	SaveGame.path = "user://maestro_visual_check.json"
	SaveGame.reset()
	PlayerSpawner.solo_slot = -1
	scene = load("res://bosses/rust_maestro/rust_maestro_fight.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	boss = scene.get_node("RustMaestroBoss")
	boss.pause_between_attacks = Vector2(99999, 99999)
	boss._wait = 99999
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.input.local_control = false
		player.player_health._invincible_timer = 99999
	await frames(150)
	await photo("idle")
	for i in SHOTS.size():
		var shot: Array = SHOTS[i]
		boss.phase = shot[1]
		boss.set_stage(shot[1])
		boss.sync.start_attack(shot[0], 93, [Vector2(300, 875), Vector2(700, 875)])
		await frames(int(shot[2] * 60))
		await photo("%02d_%s" % [i, String(shot[0]).to_snake_case()])
		boss._current.cancel()
		await frames(3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit()

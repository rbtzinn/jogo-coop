extends Node
## Piloto renderizado com comandos dos jogadores, capturas e métricas.
## Não mede dificuldade humana: protege a dupla para inspecionar todos os ataques.
## Godot --path . res://tests/cabinet_playtest.tscn -- <pasta> [qualidade 0..2]

var _out := ""
var _boss: MagicianBoss
var _bots := false
var _players: Array[Player] = []
var _elapsed := 0.0
var _frames := 0
var _calls := 0.0
var _sample_time := 0.0
var _sampling := false
var _next_dash: Array[float] = [0.0, 0.0]
var _fire := false


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() else "C:/jogo-coop/build/qa/gabinete/visual"
	DirAccess.make_dir_recursive_absolute(_out)
	Settings.quality = int(args[1]) if args.size() > 1 else 2
	Settings.apply_video()
	Settings.changed.emit()
	get_window().mode = Window.MODE_WINDOWED
	get_window().position = Vector2i(-10000, -10000)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	SaveGame.path = "user://cabinet_visual_save.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magician/magician_fight.tscn").instantiate()
	add_child(scene)
	_boss = scene.get_node("MagicianBoss")
	_boss._wait = 100000.0
	_boss.pause_between_attacks = Vector2(100000, 100000)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.input.scripted = true
		player.player_health._invincible_timer = 1000.0
		_players.append(player)
	await seconds(3.0)
	await shot("00_fase_original")
	_boss.apply_damage(_boss.health.current - _boss.phase_end_health())
	await seconds(3.0)
	_boss.apply_damage(_boss.health.current - _boss.phase_end_health())
	await seconds(1.3)
	await shot("01_desdobramento")
	await seconds(1.8)
	await shot("02_gabinete")
	_bots = true
	_sampling = true
	for attack: StringName in [&"GrabHands", &"HatPour", &"GiantCards"]:
		_boss.sync.start_attack(attack, 173, _boss._args_for(attack))
		await seconds(0.7)
		await shot(String(attack) + "_preparo")
		await seconds(0.5)
		await shot(String(attack) + "_golpe")
		while _boss._current != null and _boss._current.is_running():
			await seconds(0.1)
	var before := _boss.health.current
	_fire = true
	_boss.pause_between_attacks = Vector2(0.35, 0.7)
	_boss._wait = 0.25
	var shooting_time := 0.0
	while not _boss.is_defeated and shooting_time < 40.0:
		await seconds(0.2)
		shooting_time += 0.2
	_fire = false
	var damaged := before - _boss.health.current
	print("PLAYTEST_SHOTS_DAMAGE ", damaged)
	if not _boss.is_defeated:
		_boss.apply_damage(_boss.health.current)
	await seconds(0.9)
	await shot("90_fechamento")
	await seconds(0.9)
	await shot("91_malao")
	await seconds(1.0)
	await shot("99_vitoria")
	_sampling = false
	var report := {"quality": Settings.quality, "frames": _frames,
		"fps": _frames / maxf(_sample_time, 0.001), "mean_draw_calls": _calls / maxi(_frames, 1),
		"shots_damage": damaged, "normal_health": before, "resolution": str(get_viewport().size)}
	var file := FileAccess.open(_out.path_join("metrics.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("PLAYTEST ", JSON.stringify(report))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	get_tree().quit(0 if damaged > 0 else 1)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not _bots:
		return
	for i in _players.size():
		var player := _players[i]
		var target_x := 880.0 if i == 0 else 1060.0
		var grab: Node = _boss.get_node("Attacks/GrabHands")
		if grab.is_running():
			for strike: Array in grab._grabs:
				var shadow: LandingShadow = strike[2]
				if shadow.visible and absf(player.global_position.x - shadow.global_position.x) < 165.0:
					target_x = shadow.global_position.x + (-210.0 if i == 0 else 210.0)
		var direction := signf(target_x - player.global_position.x)
		var moving := absf(target_x - player.global_position.x) > 22.0
		player.input.move = Vector2(direction if moving else 0.0, -1.0)
		player.input.lock_held = not moving
		player.input.shoot_held = _fire
		player.input.dash_pressed = false
		player.input.jump_pressed = false
		player.input.special_pressed = false
		if moving and grab.is_running() and _elapsed > _next_dash[i]:
			player.input.dash_pressed = true
			_next_dash[i] = _elapsed + 0.9


func _process(delta: float) -> void:
	if _sampling:
		_frames += 1
		_sample_time += delta
		_calls += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)


func seconds(value: float) -> void:
	await get_tree().create_timer(value).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("CAPTURE ", name)

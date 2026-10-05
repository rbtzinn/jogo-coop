extends Node
## Captura e medição reproduzível, sem tocar no save real. Usar janela oculta, não --headless.
var _frames := 0
var _seconds := 0.0
var _calls := 0.0
var _primitives := 0.0
var _sampling := false
var _destination := ""

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := args[0] if args.size() > 0 else Levels.MENU
	_destination = args[1] if args.size() > 1 else "C:/jogo-coop/build/visual_audit"
	DirAccess.make_dir_recursive_absolute(_destination)
	SaveGame.path = "user://visual_audit_save.json"
	SaveGame.reset()
	Settings.quality = 2
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var scene := (load(scene_path) as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await get_tree().create_timer(2.0).timeout
	if args.size() > 2:
		match args[2]:
			"settings": scene._settings_menu.open()
			"shop": ShopPanel.open_for("clown", scene)
			"dressing":
				var dressing := DressingRoom.new()
				var center := CenterContainer.new()
				center.set_anchors_preset(Control.PRESET_FULL_RECT)
				scene.add_child(center)
				center.add_child(dressing)
				dressing.open()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_destination + "/capture.png")
	_sampling = true
	await get_tree().create_timer(3.0).timeout
	_sampling = false
	var report := {"scene": scene_path, "frames": _frames, "fps": _frames / maxf(_seconds, 0.001),
		"mean_frame_ms": _seconds * 1000.0 / maxi(_frames, 1),
		"draw_calls": _calls / maxi(_frames, 1), "primitives": _primitives / maxi(_frames, 1),
		"resolution": str(get_viewport().size), "quality": Settings.quality}
	var file := FileAccess.open(_destination + "/metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("VISUAL_AUDIT ", JSON.stringify(report))
	get_tree().quit()

func _process(delta: float) -> void:
	if _sampling:
		_frames += 1
		_seconds += delta
		_calls += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		_primitives += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)

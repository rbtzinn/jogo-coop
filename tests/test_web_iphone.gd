extends Node
## Rodar: Godot --headless --path . res://tests/test_web_iphone.tscn [-- capture <pasta>]
## iPhone pelo navegador: conta das bordas do sistema (entalhe, barrinha de Início) na tela do jogo, aviso de
## "Adicionar à Tela de Início" que só aparece uma vez, e o modo app na exportação Web.

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := Vector2(1920, 1080)
	# iPhone deitado (844x390): faixas pretas de 75 px dos lados cobrem o entalhe (47); a barrinha de Início
	# (21 embaixo) entra no jogo.
	var phone := Device.insets_in_game(Vector4(47, 0, 47, 21), Vector2(844, 390), game)
	check(is_zero_approx(phone.x) and is_zero_approx(phone.z), "notch hidden by the side bands needs no shift")
	check(absf(phone.w - 21.0 * 1080.0 / 390.0) < 0.5, "home bar shifts bottom buttons in game units")
	var tight := Device.insets_in_game(Vector4(60, 0, 0, 0), Vector2(1920, 1080), game)
	check(is_equal_approx(tight.x, 60.0), "inset inside the game area counts fully")
	check(Device.insets_in_game(Vector4(10, 10, 10, 10), Vector2.ZERO, game) == Vector4.ZERO, "missing page size is ignored")
	check(Device.safe_insets(game) == Vector4.ZERO and not Device.is_installed_web_app(), "desktop build has no web insets")
	check(not HomeScreenTip.wanted(), "tip never shows outside the iPhone browser")
	var presets := ConfigFile.new()
	presets.load("res://export_presets.cfg")
	var head := ""
	for section in presets.get_sections():
		if presets.get_value(section, "name", "") == "Web":
			head = presets.get_value(section + ".options", "html/head_include", "")
			var icon: String = presets.get_value(section + ".options", "progressive_web_app/icon_180x180", "")
			check(ResourceLoader.exists(icon), "home screen icon 180x180 exists")
			check(presets.get_value(section + ".options", "progressive_web_app/enabled", false), "web app mode enabled")
	check("viewport-fit=cover" in head and "black-translucent" in head, "page uses the whole screen with a see-through status bar")
	# Aviso: aparece, fecha no "Entendi" e fica marcado como visto.
	var seen_before := Settings.home_screen_tip_seen
	Settings.home_screen_tip_seen = false
	# Dentro de uma tela cheia com o tema dos menus, como no menu inicial.
	var menu := Control.new()
	menu.theme = UiTheme.build()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(menu)
	menu.size = get_viewport().get_visible_rect().size
	var tip := HomeScreenTip.new()
	menu.add_child(tip)
	await get_tree().process_frame
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	if args.size() > 1 and args[0] == "capture":
		DirAccess.make_dir_recursive_absolute(args[1])
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[1].path_join("home_screen_tip.png"))
	var buttons := tip.find_children("*", "Button", true, false)
	check(buttons.size() == 1, "tip has one close button")
	var closed := [false]
	tip.closed.connect(func() -> void: closed[0] = true)
	(buttons[0] as Button).pressed.emit()
	check(closed[0] and Settings.home_screen_tip_seen, "closing marks the tip as seen")
	Settings.home_screen_tip_seen = seen_before
	Settings._save()
	print("FAILURES: ", failures)
	get_tree().quit(failures)

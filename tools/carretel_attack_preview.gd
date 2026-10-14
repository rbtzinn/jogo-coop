extends Control
## Demonstração visual sem jogador/dano. A luta ainda será uma etapa própria.
const VISUAL := preload("res://bosses/madame_carretel/carretel_attack_visual.tscn")
const LABELS := {
	&"scissors":"Corte de tesoura", &"tape":"Chicote de fita", &"needles":"Leque de agulhas",
	&"parry":"Agulha de aparar", &"cloth":"Cortina de tecido", &"armor_attack":"Botões mecânicos",
}
const QA := "res://build/qa/carretel/attacks/"
@export var arena_scene: PackedScene
@export var clean_view := false
var arena: Node2D
var hud := CanvasLayer.new()
var demo: Node2D
var keys: Array = LABELS.keys()
var index := 0
var automatic := true
var capture_mode := false
var light := false
var info := Label.new()
var caption := Label.new()
var background := ColorRect.new()
var progress := ProgressBar.new()
var buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_window().title = "Madame Carretel — Ataques visíveis (prévia)"
	theme = UiTheme.build()
	FilmOverlay.visible = false
	background.color = Color("171622")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	if arena_scene!=null:
		arena = arena_scene.instantiate()
		add_child(arena)
		background.visible = false
		get_window().title = "Madame Carretel — Ateliê clean (prévia)"
	else:
		var stage := ColorRect.new()
		stage.position = Vector2(100,930)
		stage.size = Vector2(1720,5)
		stage.color = Color("74505b")
		add_child(stage)
	demo = VISUAL.instantiate()
	demo.position = Vector2(1530,930)
	add_child(demo)
	hud.layer = 10
	hud.visible = not clean_view
	add_child(hud)
	var heading := Label.new()
	heading.position = Vector2(40,24)
	heading.text = "Madame Carretel — ataques animados"
	heading.add_theme_font_size_override("font_size",38)
	hud.add_child(heading)
	info.position = Vector2(42,78)
	info.add_theme_font_size_override("font_size",25)
	hud.add_child(info)
	var row := HBoxContainer.new()
	row.position = Vector2(40,130)
	row.add_theme_constant_override("separation",10)
	hud.add_child(row)
	for i in keys.size():
		var button := Button.new()
		button.text = LABELS[keys[i]]
		button.custom_minimum_size = Vector2(285,58)
		button.toggle_mode = true
		button.pressed.connect(func() -> void:
			automatic = false
			_select(i))
		row.add_child(button)
		buttons.append(button)
	caption.position = Vector2(42,215)
	caption.add_theme_font_size_override("font_size",24)
	hud.add_child(caption)
	progress.position = Vector2(42,978)
	progress.size = Vector2(1836,6)
	progress.show_percentage = false
	hud.add_child(progress)
	var help := Label.new()
	help.position = Vector2(42,1000)
	help.text = "← → escolher  ·  Espaço pausar  ·  Enter repetir  ·  A automático  ·  L fundo claro  ·  F filme  ·  H interface\nPrévia de animações e efeitos — ainda sem combate/dano"
	help.add_theme_font_size_override("font_size",20)
	hud.add_child(help)
	demo.finished.connect(func(_key: StringName) -> void:
		if automatic: _select(index+1))
	_select(0)
	if "arena_capture" in OS.get_cmdline_user_args():
		capture_mode = true
		_capture_arena()
	elif "capture" in OS.get_cmdline_user_args():
		capture_mode = true
		_capture()

func _select(which: int) -> void:
	index = posmod(which,keys.size())
	demo.play_attack(keys[index])
	for i in buttons.size():
		buttons[i].set_pressed_no_signal(i==index)
	caption.text = {
		&"scissors":"O arco claro mostra o alcance do corte; o brilho marca o fechamento.",
		&"tape":"A fita se estende, ondula e recolhe. O perigo acompanha a fita visível.",
		&"needles":"Ponta larga + fio em movimento: três trajetórias separadas e legíveis.",
		&"parry":"Turquesa + borda clara + estrela: esta agulha permite aparar na futura luta.",
		&"cloth":"O contorno avisa a área. A cortina desce presa ao trilho e depois recolhe.",
		&"armor_attack":"Os botões giram e percorrem arcos completos, sem desaparecer no cenário.",
	}[keys[index]]

func _process(_delta: float) -> void:
	if demo==null:
		return
	var phase_text := {&"warning":"AVISO — prepare-se", &"active":"ATAQUE — efeito visível", &"recovery":"RECOLHIMENTO — ataque encerrado"}
	info.text = "%d / %d  ·  %s  ·  %s" % [index+1,keys.size(),phase_text[demo.phase],"pausado" if demo.paused else ("automático" if automatic else "manual")]
	info.modulate = Color("ffd987") if demo.phase==&"warning" else (ParryStyle.LIGHT if keys[index]==&"parry" else Color("fff2d6"))
	progress.max_value = demo.duration(keys[index])
	progress.value = demo.elapsed

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_RIGHT:
			automatic = false
			_select(index+1)
		KEY_LEFT:
			automatic = false
			_select(index-1)
		KEY_SPACE:
			automatic = false
			demo.paused = not demo.paused
		KEY_ENTER:
			demo.paused = false
			_select(index)
		KEY_A:
			automatic = not automatic
			demo.paused = false
			_select(index)
		KEY_L:
			light = not light
			background.color = Color("776b69") if light else Color("171622")
			if arena!=null:
				arena.visible = not light
				background.visible = light
		KEY_F:
			FilmOverlay.visible = not FilmOverlay.visible
		KEY_H:
			hud.visible = not hud.visible
		_:
			return
	get_viewport().set_input_as_handled()

func _capture_arena() -> void:
	const OUT := "res://build/qa/carretel/arena/"
	automatic = false
	demo.paused = true
	hud.visible = false
	DirAccess.make_dir_recursive_absolute(OUT)
	demo.visible = false
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"cenario_limpo.png")
	demo.visible = true
	for i in keys.size():
		_select(i)
		var warning: float = demo.ATTACKS[keys[i]].warning
		for sample in [{"label":"warning","time":warning*0.6},{"label":"active","time":warning+0.24},{"label":"flight","time":warning+minf(0.72,demo.ATTACKS[keys[i]].active*0.8)}]:
			demo.seek(sample.time)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OUT+String(keys[i])+"_"+sample.label+".png")
	_select(3)
	demo.seek(1.45)
	FilmOverlay.visible = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"parry_film.png")
	FilmOverlay.visible = false
	for i in keys.size():
		_select(i)
		for f in 30:
			demo.seek(float(f)*demo.duration(keys[i])/30.0)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var frame := get_viewport().get_texture().get_image()
			frame.resize(960,540,Image.INTERPOLATE_LANCZOS)
			frame.save_png(OUT+"gif_%02d_%02d.png" % [i,f])
	get_tree().quit()

func _capture() -> void:
	automatic = false
	demo.paused = true
	DirAccess.make_dir_recursive_absolute(QA)
	for i in keys.size():
		_select(i)
		var warning: float = demo.ATTACKS[keys[i]].warning
		for sample in [{"label":"warning","time":warning*0.6},{"label":"active","time":warning+0.24},{"label":"flight","time":warning+minf(0.72,demo.ATTACKS[keys[i]].active*0.8)},{"label":"recovery","time":demo.duration(keys[i])-0.1}]:
			demo.seek(sample.time)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(QA+String(keys[i])+"_"+sample.label+".png")
	# Readability under light scenery and the game's actual film filter.
	_select(3)
	demo.seek(1.45)
	background.color = Color("776b69")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(QA+"parry_light.png")
	FilmOverlay.visible = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(QA+"parry_film.png")
	FilmOverlay.visible = false
	background.color = Color("171622")
	# Deterministic frames for a GIF of the real Godot composition.
	for i in keys.size():
		_select(i)
		for f in 30:
			demo.seek(float(f)*demo.duration(keys[i])/30.0)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			image.resize(960,540,Image.INTERPOLATE_LANCZOS)
			image.save_png(QA+"gif_%02d_%02d.png" % [i,f])
	get_tree().quit()

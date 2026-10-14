extends Control
## Prévia de P01. Não carrega jogadores, inimigos nem altera saves da campanha.
var visual: Node2D
var bg := ColorRect.new()
var light := false
var labels: Array[Label] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_window().title = "Maestro Ferrugem — arte-base (prévia)"
	theme = UiTheme.build()
	FilmOverlay.visible = false
	bg.color = Color("202a32")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	visual = load("res://bosses/rust_maestro/rust_maestro_visual.tscn").instantiate()
	visual.position = Vector2(1220,950)
	visual.scale = Vector2.ONE*0.72
	add_child(visual)
	label("Maestro Ferrugem",Vector2(70,60),46)
	label("PARTE 1 — DESENHO-BASE",Vector2(72,130),24)
	label("O regente mecânico das Oficinas.\n\nCasaca azul-petróleo, batuta, metal\nenvelhecido e três tubos de órgão.\n\nEsta é uma prévia da arte-base.\nAinda não tem animações ou combate.",Vector2(72,280),27)
	label("L: fundo claro/escuro  ·  H: ocultar textos\n← →: comparar direção  ·  R: restaurar",Vector2(72,960),23)
	if "capture" in OS.get_cmdline_user_args(): capture.call_deferred()

func label(text: String,at: Vector2,size: int) -> void:
	var item := Label.new()
	item.text = text
	item.position = at
	item.add_theme_font_size_override("font_size",size)
	item.add_theme_color_override("font_color",Color("e8d7b9"))
	add_child(item)
	labels.append(item)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_L:
			light = not light
			bg.color = Color("e7e4dc") if light else Color("202a32")
			for item in labels: item.add_theme_color_override("font_color",Color("282c31") if light else Color("e8d7b9"))
		KEY_H:
			for item in labels: item.visible = not item.visible
		KEY_LEFT: visual.scale.x = absf(visual.scale.x)
		KEY_RIGHT: visual.scale.x = -absf(visual.scale.x)
		KEY_R: visual.scale = Vector2.ONE*0.72
		_: return
	get_viewport().set_input_as_handled()

func capture() -> void:
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/qa/maestro/p01_preview.png")
	get_tree().quit()

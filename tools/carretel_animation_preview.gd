extends Control
## Prévia das artes animadas; não altera saves nem inicia a luta futura.
const LABELS := {
	"idle":"Espera e piscar", "scissors":"Tesoura: aviso, corte e recuperação",
	"tape":"Fita métrica", "needles":"Arremesso de agulhas", "cloth":"Prova de roupa",
	"hurt":"Reação de dano", "armor":"Manequim de guerra: transformação",
	"armor_attack":"Manequim de guerra: ataque", "defeat":"Derrota",
}
var visual: Node2D
var clips: Array[StringName] = []
var index := 0
var automatic := true
var elapsed := 0.0
var title := Label.new()
var state := Label.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_window().title = "Madame Carretel — Animações (prévia)"
	theme = UiTheme.build()
	# Conferência de arte limpa; não altera a configuração gráfica salva do jogo.
	FilmOverlay.visible = false
	var bg := ColorRect.new()
	bg.color = Color("141221")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var floor := ColorRect.new()
	floor.color = Color("3e2d3d")
	floor.position = Vector2(100,930)
	floor.size = Vector2(1720,3)
	add_child(floor)
	visual = load("res://bosses/madame_carretel/carretel_visual.tscn").instantiate()
	visual.position = Vector2(1120,930)
	visual.scale = Vector2.ONE*1.08
	add_child(visual)
	for key in LABELS:
		if visual.sprite_frames.has_animation(StringName(key)):
			clips.append(StringName(key))
	title.position = Vector2(50,24)
	title.add_theme_font_size_override("font_size",38)
	add_child(title)
	state.position = Vector2(50,82)
	state.add_theme_font_size_override("font_size",24)
	add_child(state)
	var column := VBoxContainer.new()
	column.position = Vector2(50,150)
	column.add_theme_constant_override("separation",10)
	add_child(column)
	for i in clips.size():
		var button := Button.new()
		button.text = LABELS[String(clips[i])]
		button.custom_minimum_size = Vector2(510,56)
		button.pressed.connect(func() -> void:
			automatic = false
			_select(i))
		column.add_child(button)
	var help := Label.new()
	help.text = "← → trocar sequência  ·  Espaço pausar/continuar\nEnter repetir  ·  A alternar demonstração automática\nPrévia de arte — sem lógica de luta"
	help.position = Vector2(50,955)
	help.add_theme_font_size_override("font_size",20)
	add_child(help)
	_select(0)
	if "capture" in OS.get_cmdline_user_args():
		_capture()

func _select(which: int) -> void:
	index = posmod(which,clips.size())
	elapsed = 0.0
	visual.sprite.frame = 0
	visual.play(clips[index])
	title.text = "Madame Carretel — " + LABELS[String(clips[index])]

func _process(delta: float) -> void:
	if clips.is_empty():
		return
	elapsed += delta
	state.text = "%d / %d  ·  quadro %d / %d  ·  %s" % [index+1,clips.size(),
		visual.sprite.frame+1,visual.sprite_frames.get_frame_count(clips[index]),
		"automático" if automatic else "manual"]
	if automatic and elapsed > maxf(3.0,visual.duration(clips[index])+1.0):
		_select(index+1)

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
			if visual.sprite.is_playing(): visual.sprite.pause()
			else: visual.sprite.play()
		KEY_ENTER:
			_select(index)
		KEY_A:
			automatic = not automatic
			elapsed = 0.0
		_:
			return
	get_viewport().set_input_as_handled()

func _capture() -> void:
	automatic = false
	DirAccess.make_dir_recursive_absolute("res://build/qa/carretel")
	for i in clips.size():
		_select(i)
		await get_tree().create_timer(0.65).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/qa/carretel/"+String(clips[i])+".png")
	get_tree().quit()

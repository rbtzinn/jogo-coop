extends Control
## Apresentação de abertura: progresso real do carregamento, sem alterar a partida.
var _progress := ProgressBar.new()
var _status := Label.new()
var _requested := false

func _ready() -> void:
	theme = UiTheme.build()
	var background := ColorRect.new()
	background.color = UiTheme.NIGHT
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 30)
	center.add_child(column)
	column.add_child(UiTheme.section_label("AS LUZES ESTÃO ACENDENDO", 24))
	column.add_child(UiTheme.title_label("Respeitável Público", 78, true))
	_progress.custom_minimum_size = Vector2(780, 8)
	_progress.show_percentage = false
	_progress.add_theme_stylebox_override("background", UiTheme._box(UiTheme.NIGHT_LIGHT, UiTheme.NIGHT_LIGHT, 0, 0))
	_progress.add_theme_stylebox_override("fill", UiTheme._box(UiTheme.GOLD, UiTheme.GOLD, 0, 0))
	column.add_child(_progress)
	_status.text = "Preparando o picadeiro…"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 24)
	column.add_child(_status)
	# Um quadro garante que a abertura apareça antes do pedido, sem um timer artificial.
	await get_tree().process_frame
	var error := ResourceLoader.load_threaded_request(Levels.MENU)
	_requested = error == OK
	if not _requested:
		_status.text = "Não foi possível abrir o menu. Pressione Enter para tentar novamente."

func _process(_delta: float) -> void:
	if not _requested:
		return
	var progress := []
	var state := ResourceLoader.load_threaded_get_status(Levels.MENU, progress)
	if not progress.is_empty():
		_progress.value = progress[0] * 100.0
	if state == ResourceLoader.THREAD_LOAD_LOADED:
		_requested = false
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(Levels.MENU))
	elif state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_requested = false
		_status.text = "Não foi possível abrir o menu. Pressione Enter para tentar novamente."

func _unhandled_input(event: InputEvent) -> void:
	if not _requested and event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file(Levels.MENU)

extends CanvasLayer
## Menu de pausa (Esc ou Start): continuar, configurações e sair.
## Por enquanto pausa o jogo inteiro; no online (etapa 2b) a pausa não vai parar a partida.

var _root: Control
var _main_panel: PanelContainer
var _settings_menu: SettingsMenu
var _continue_button: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiTheme.build()
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.05, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	_main_panel = PanelContainer.new()
	center.add_child(_main_panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	_main_panel.add_child(layout)
	layout.add_child(UiTheme.title_label("Pausa", 72))
	_continue_button = _add_button(layout, "Continuar", close)
	_add_button(layout, "Configurações", _open_settings)
	_add_button(layout, "Sair do jogo", func() -> void: get_tree().quit())

	_settings_menu = SettingsMenu.new()
	_settings_menu.hide()
	_settings_menu.closed.connect(_on_settings_closed)
	center.add_child(_settings_menu)

	_root.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if not _root.visible:
		open()
	elif _main_panel.visible:
		close()
	get_viewport().set_input_as_handled()


func open() -> void:
	_root.show()
	_main_panel.show()
	_settings_menu.hide()
	get_tree().paused = true
	_continue_button.grab_focus()


func close() -> void:
	_root.hide()
	get_tree().paused = false


func _open_settings() -> void:
	_main_panel.hide()
	_settings_menu.open()


func _on_settings_closed() -> void:
	_main_panel.show()
	_continue_button.grab_focus()


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 0)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
